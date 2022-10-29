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
   cldfbench makecldf --with-cldfreadme cldfbench_lexibank_analysed.py
   cd ../code
   ```

4. extract character matrices
   ```shell
   julia extractMatrices.jl
   ```

   

The matrices created are stored in the subdirectory `lexibank/characterMatrices`.

