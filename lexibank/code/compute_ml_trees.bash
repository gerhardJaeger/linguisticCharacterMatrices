mkdir ../data/phylip_mltrees
for f in `ls ../data/phylip_files/`
do
    db=`basename $f .phy`
    raxml-ng --msa ../data/phylip_files/$f --model BIN --prefix ../data/phylip_mltrees/$db.phy --redo
done


mkdir ../data/catg_mltrees
for f in `ls ../data/catg/`
do
    db=`basename $f .catg`
    raxml-ng --msa ../data/catg/$f --model BIN --prefix ../data/catg_mltrees/$db --prob-msa on --redo
done