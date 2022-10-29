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
   pip install -e .
   cldfbench download cldfbench_lexibank_analysed.py
   ```
   
4. extract character matrices
   ```shell
   cd ../code
   julia extractMatrices.jl
   ```
   
   

The matrices created are stored in the subdirectory `lexibank/characterMatrices`.

