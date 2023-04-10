## Extracting character matrices from expert cognacy judgments in lexibank and conduct phylogenetic inference

### workflow

You need to have anaconda/miniconda installed on your machine.

1. create conda environment from `package-list.txt`

   ```shell
   conda env create -f lexibank.yml
   ```

2. activate the new environment

   ```shell
   conda activate lexibank
   ```

3. install `lexibank-analysed`

   ```shell
   git clone https://github.com/lexibank/lexibank-analysed
   cd lexibank-analysed
   git checkout v0.2
   pip install -e .
   cldfbench download cldfbench_lexibank_analysed.py
   ```

4. extract character matrices
   ```shell
   cd ../lexibank/code
   julia processData.jl
   ```

   The results created are stored in the subdirectory `lexibank/data`. The subdirectories are

   - `glottologTrees`: Glottolog trees
   - `nexus_files`: character matrices in Nexus format
   - `phylip_files`: character matrices in Phylip format
   - `catg_files`: character matrices in catg format (https://github.com/amkozlov/raxml-ng/wiki/Input-data#catg-file-format) for use with `raxml-ng` (https://github.com/amkozlov/raxml-ng/)

5. compute maximum likelihood trees with `raxml-ng` (https://github.com/amkozlov/raxml-ng)

   ```shell
   bash compute_ml_trees.bash
   ```
   The results are stored in the subdirectories 

   - `lexibank/data/phylip_mltrees`: ML trees from binarized cognate-class characters where all synonyms are used as presence characters
   - `lexibank/data/catg_mltrees`: ML trees from binarized cognate-class characters with uncertain character values in case of synonymy



6. compute posterior tree distributions with `mrbayes` 

   ```shell
   bash run_mrbayes.sh
   R --vanilla < collect_posterior_trees.r
   ```

   The results are stored in `lexibank/data/mrbayes_posteriors`.
