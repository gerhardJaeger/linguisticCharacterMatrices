## Extracting character matrices from expert cognacy judgments in lexibank

### workflow

You need to have anaconda/miniconda installed on your machine.

1. create conda environment from lexibank.yml

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

- `catg_files`: character matrices in catg format (https://github.com/amkozlov/raxml-ng/wiki/Input-data#catg-file-format) for use with `raxml-ng` (https://github.com/amkozlov/raxml-ng/)
- `glottologTrees`: Glottolog trees
- `nexus_files`: character matrices in Nexus format
- `phylip_files`: character matrices in Phylip format

