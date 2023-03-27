using Pkg
Pkg.activate(".")
Pkg.instantiate()

##

using DataFrames
using CSV
using Pipe
using DataStructures
using Base.Iterators
using ProgressMeter
using Random


##

pth = "../lexibank-analysed/raw"

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
db = cog_dbs[1]

@showprogress for db in cog_dbs
    languages = CSV.File(joinpath(pth, db, "cldf", "languages.csv")) |> DataFrame
    cognates = CSV.File(joinpath(pth, db, "cldf", "cognates.csv")) |> DataFrame
    forms = CSV.File(joinpath(pth, db, "cldf", "forms.csv")) |> DataFrame
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
    glottologTaxa = unique(d.Glottocode)

    df = @pipe d |>
            select(
                _,
                [:Language_ID, :Parameter_ID, :Cognateset_ID, :Form]
            ) |>
            dropmissing |>
            unique |>
            rename!(
                _,
                [:language, :concept, :cc, :form]
            ) |>
            insertcols(_, :fullCC => join.(zip(_.concept, _.cc), ":"))

    concepts = String.(df.concept |> unique)
    taxa = String.(df.language |> unique) |> sort
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
                    v = 1.0 / length(ccc)
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

    outpth = "../catg"

    try
        mkdir(outpth)
    catch e
    end


    open(joinpath(outpth, "$db.catg"), "w") do file
        write(file, catg)
    end
    @info db
end