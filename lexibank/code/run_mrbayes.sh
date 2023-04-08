for f in mrbayes_scripts/*mb.nex
do
    mpirun -np 4 mb-mpi $f &
done
