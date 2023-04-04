using Pkg
Pkg.activate(".")
Pkg.instantiate()

##

using DataFrames
using CSV
using Pipe
using ProgressMeter
##


ENV["PYTHON"] = readchomp(`which python`)
Pkg.build("PyCall")
using PyCall

ete3 = pyimport("ete3")
##

glottologF = "../data/tree_glottolog_newick.txt"

isfile(glottologF) || download(
    "https://cdstar.eva.mpg.de/bitstreams/EAEA0-F8BB-0AB6-96FA-0/tree_glottolog_newick.txt",
    glottologF
)

##

raw = readlines(glottologF);

##

trees = []

for ln in raw
    ln = strip(ln)
    ln = replace(ln, r"\'[A-ZÄÖÜŌ][^[]*\[" => "[")
    ln = replace(ln, r"\][^']*\'" => "]")
    ln = replace(ln, "''" => "")
    ln = replace(ln, r"\[|\]" => "")
    ln = replace(ln, ":1" => "")
    tr = ete3.Tree(ln, format=1)
    push!(
        trees,
        tr
    )
end

##


glot = ete3.Tree()

for t in trees
    glot.add_child(t.copy())
end

glottolog_taxa = glot.get_leaf_names()

##

internal_named_nodes = [
    nd for nd in glot.traverse("postorder")
    if (!nd.is_leaf()) && (nd.name != "") && (nd.name ∉ glottolog_taxa)
]

for nd in internal_named_nodes
    nd.add_child(name = nd.name)
end

glottolog_taxa = glot.get_leaf_names()


glot.write(outfile="../data/glottolog_complete.tre", format=9)

##

pth = "../../lexibank-analysed/raw"

datasets = readdir(pth)

filter!(x -> x != "README.md", datasets)



##

cog_dbs = []
for db in datasets
    if isfile(joinpath(pth, db, "cldf", "cognates.csv"))
        push!(cog_dbs, db)
    end
end

##

function merge_db_data(db)
    cognates = CSV.File(joinpath(pth, db, "cldf", "cognates.csv")) |> DataFrame
    forms = CSV.File(joinpath(pth, db, "cldf", "forms.csv")) |> DataFrame
    languages = CSV.File(joinpath(pth, db, "cldf", "languages.csv")) |> DataFrame
    d = outerjoin(
        forms,
        cognates,
        on=:ID => :Form_ID,
        makeunique=true,
    )
    d = outerjoin(
        d,
        languages,
        on=:Language_ID => :ID,
        makeunique=true
    )
    dropmissing!(d, :Glottocode)
    missing_taxa = [x for x in unique(d.Glottocode) if x ∉ glottolog_taxa]
    for l in missing_taxa
        @info "$db $l"
    end
    filter!(x -> x.Glottocode ∈ glottolog_taxa, d)
    df = @pipe d |>
               select(
                   _,
                   [:Language_ID, :Parameter_ID, :Cognateset_ID, :Glottocode]
               ) |>
               dropmissing |>
               unique |>
               rename!(_, [:language, :concept, :cc, :Glottocode])
    return df
end

##

dfDict = Dict()
for db in cog_dbs
    dfDict[db] = merge_db_data(db)
end

##

function get_glottolog_tree(db)
    df = dfDict[db]

    db_glottocodes = unique(df.Glottocode)

    glot_db = glot.copy()

    glot_db.prune([(glot_db & l) for l in db_glottocodes])

    for g in db_glottocodes
        ll = filter(x -> x.Glottocode == g, df).language
        for l in ll
            (glot_db & g).add_child(name = l)
        end
    end
    glot_db.prune([(glot_db&l) for l in df.language])

    glot_db
end
##

glot_pth = "../data/glottologTrees"

try
    mkdir(glot_pth)
catch e
end

@showprogress for db in cog_dbs
    get_glottolog_tree(db).write(
        outfile=glot_pth*"/"*db*"_glottolog.tre", 
        format=9
    )
end



##
function db2charMtx(db)
    df = dfDict[db]
    concepts = df.concept |> unique
    dfs_ = []
    for c in concepts
        dfc = @pipe df |>
                    filter(x -> x.concept == c, _) |>
                    unique |>
                    unstack(_, :cc, :language, :concept) |>
                    _[:, 2:end] |>
                    1 .- ismissing.(_)
        push!(dfs_, dfc)
    end
    vcat(dfs_..., cols=:union)
end
##

charMatrices = db2charMtx.(cog_dbs)

##

function writePhy(cm, fn)
    function printChar(ch)
        ismissing(ch) ? "-" : string(ch)
    end

    pad = maximum(length.(names(cm))) + 5

    phy = """$(size(cm, 2)) $(size(cm, 1))

    """
    for l in names(cm)
        phy *= rpad(l, pad) * join(printChar.(cm[:, l])) * "\n"
    end
    open(fn, "w") do file
        write(file, phy)
    end
end

##

pth_phy = "../data/phylip_files/"
try
    mkdir(pth_phy)
catch e
end

for (db, cm) in zip(cog_dbs, charMatrices)
    writePhy(cm, joinpath(pth_phy, db * ".phy"))
end




##
function writeCharMtx(cm, fn)
    function printChar(ch)
        ismissing(ch) ? "-" : string(ch)
    end

    pad = maximum(length.(names(cm))) + 5

    nex = """#Nexus
    BEGIN DATA;
    DIMENSIONS ntax=$(size(cm, 2)) nchar = $(size(cm, 1));
    FORMAT DATATYPE=Restriction GAP=? MISSING=- interleave=no;
    MATRIX

    """
    for l in names(cm)
        nex *= rpad(l, pad) * join(printChar.(cm[:, l])) * "\n"
    end
    nex *= ";\nEND"
    open(fn, "w") do file
        write(file, nex)
    end
end


##

pth_nex = "../data/nexus_files"

try
    mkdir(pth_nex)
catch e
end

for (db, cm) in zip(cog_dbs, charMatrices)
    writeCharMtx(cm, joinpath(pth_nex, db * ".nex"))
end


##


function get_catg(db)
    df = dfDict[db]
    concepts = String.(df.concept |> unique)
    taxa = String.(df.language |> unique) |> sort
    insertcols!(
        df,
        :fullCC => join.(zip(df.concept, df.cc), ":")
    )
    cClasses = String.(df.fullCC |> unique)

    lc2cc = Dict()
    for l in taxa, c in concepts
        ccs = filter(
            x -> x.language == l && x.concept == c,
            df
        ).fullCC
        lc2cc[String(l), String(c)] = ccs
    end

    entries_ = []
    for c in concepts
        ccc = filter(x -> x.concept == c, df).fullCC |> unique
        for l in taxa
            nCC = length(lc2cc[l, c])
            for cc in ccc
                if nCC == 0
                    v = missing
                elseif cc ∈ lc2cc[l, c]
                    v = 1.0 / nCC
                else
                    v = 0
                end
                push!(
                    entries_,
                    (cc=cc, language=l, prob1=v, prob0=1 - v)
                )
            end
        end
    end

    entries = sort(DataFrame(entries_), [:cc, :language])
    entries[ismissing.(entries.prob1), :prob1] .= 1.0
    entries[ismissing.(entries.prob0), :prob0] .= 1.0

    sort!(entries, [:cc, :language, :prob1])

    insertcols!(entries, :ml => Int.(round.(entries.prob1, digits=0)))

    blockDict = @pipe entries |>
                    groupby(_, :cc) |>
                    combine(_, x -> join(x.ml)) |>
                    Dict(zip(_.cc, _.x1))

    entriesDict = @pipe entries |>
                        groupby(_, :cc) |>
                        combine(
                            _,
                            x -> join(
                                ["$(round(y.prob0, digits=3)),$(round(y.prob1, digits=3))"
                                for y in eachrow(x)],
                                " "
                            )
                        ) |>
                        Dict(zip(_.cc, _.x1))

    catg = "$(length(taxa)) $(length(cClasses))\n"
    catg *= join(taxa, " ") * "\n"
    for cc in cClasses
        catg *= blockDict[cc] * " " * entriesDict[cc] * "\n"
    end
    catg
end

##

pth_catg = "../data/catg_files"

try
    mkdir(pth_catg)
catch e
end

@showprogress for db ∈ cog_dbs
    open(joinpath(pth_catg, "$db.catg"), "w") do file
        write(file, get_catg(db))
    end
end
