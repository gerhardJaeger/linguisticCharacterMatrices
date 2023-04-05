
mkdir -p ../data/phylip_mltrees
for f in `ls ../data/phylip_files/`
do
    db=`basename $f .phy`
    raxml-ng --msa ../data/phylip_files/$f --model BIN --prefix ../data/phylip_mltrees/$db.phy --redo
done


mkdir -p ../data/catg_mltrees
for f in `ls ../data/catg_files/`
do
    db=`basename $f .catg`
    raxml-ng --msa ../data/catg_files/$f --model BIN --prefix ../data/catg_mltrees/$db --prob-msa on --redo
done

for f in `ls ../data/phylip_mltrees/*bestTree`
do
    b=`basename $f .phy.raxml.bestTree`
    cp $f ../data/phylip_mltrees/$b"_mltree.tre"
done

for f in `ls ../data/catg_mltrees/*bestTree`
do
    b=`basename $f .raxml.bestTree`
    cp $f ../data/catg_mltrees/$b"_catg_mltree.tre"
done