# Bioinfoconda

A framework to manage workflows for medium-size data analysis projects, 
based on Conda environments and easily exportable to Docker images.

In Bioinfoconda, each project has its own directory, conda environment, 
local libraries and executables. As soon as you `cd` into the project 
directory, the environment is automatically set up with project-specific 
files. Bioinfoconda also provides a way to download and store 
third-party data sets in an organised fashion. Projects will also be 
easily incapsulated in Docker containers.

## Installation Instructions (Linux only)

1. Clone this repository; if you want a system-wide installation and 
   have root permissions, you can clone it for instance directly under 
the root directory, while if you are an unprivileged user you can clone 
it under your home directory.
    * `git clone --recurse-submodules 
      https://github.com/fmarotta/bioinfoconda`

2. Install Miniconda (you can install it in any path, but if you want to 
   have everything in a place, install it under bioinfoconda)
    * Follow the instructions [here](https://conda.io/docs/user-guide/install/index.html)

3. Install direnv (if you do not have rootly powers, you can install it 
   under bioinfoconda; there probably is a packaged version for your 
system)
    * See [here](https://github.com/direnv/direnv) for the instructions

4. (Optional) Install Docker
    * Instructions [here](https://docs.docker.com/install/)

5. Set up the environment
    * Set BIOINFO\_ROOT to the path where you cloned the repository
    * Add bioinfoconda's executables to your PATH
    * Add miniconda's executables to your PATH
    * Add bioinfotree's executables to your PATH
    * Add bioinfotree's python and perl libraries to the environment
    * Make sure you have LC\_ALL set
    * Configure the bashrc so that direnv works

6. (Useful in a multi-user system) Create a 'bioinfoconda' group and fix 
   the directory permissions (then add the users supposed to use 
bioinfoconda to the 'bioinfoconda' group)
    * `sudo addgroup bioinfoconda`
    * `sudo chown -R root:bioinfoconda $BIOINFO_ROOT`
    * `sudo chmod -R 2775 $BIOINFO_ROOT`

---

Step 5., which is probably the one that requires most work, translates 
into appending the following to the *.bashrc*'s of all the users of 
Bioinfoconda

```
# Bioinfoconda configuration
# ----------------------------------------------------------------------

# Export environment variables
export BIOINFO_ROOT="/bioinfoconda"
export PATH="$BIOINFO_ROOT/bioinfotree/local/bin:/bioinfoconda/prj/bioinfoconda/local/bin:/bioinfoconda/miniconda/bin:$PATH"
export PYTHONPATH="$BIOINFO_ROOT/bioinfotree/local/lib/python"
export PERL5LIB="$BIOINFO_ROOT/bioinfotree/local/lib/perl"
export LC_ALL="en_US.utf8"

# Configure direnv
eval "$(direnv hook bash)"

# Show conda environment in prompt
# NOTE: direnv is not able to properly update the prompt when the conda 
environment changes, hence we need this to recover the functionality.
show_conda_env()
{
        if [ -n "$CONDA_DEFAULT_ENV" ] && \
           [ "$CONDA_DEFAULT_ENV" != "base" ] && \
           [ "${PS1:0:1}" != "(" ]; then
        echo "($CONDA_DEFAULT_ENV) "
        fi
}
export -f show_conda_env
PS1='$(show_conda_env)'$PS1
```

If you are the system administrator (or if you have a great influence 
over him/her), you may as well put the environment variables in 
*/etc/environment* and append the other instructions to 
*/etc/skel/.bashrc*, so that the configuration will be available to all 
new users.

Remember to edit the previous instructions according to your 
requirements and taste (for instance, you could need to change the path 
names; also make sure not to override any environmental variable which 
was already set for your system).

## Introduction

TODO: environment variables, miniconda, bioinfotree

## Usage Instructions

### Creating Projects

To create a new project, simply run

```
X-mkprj PROJECT_NAME
```

This will: create a directory structure for the project; add default 
Dockerfile and Snakefile; initialise a git repository; create a conda 
environment; set up direnv. You can use some of `X-mkprj`'s options to 
disable the features you do not need. Projects are created in the 
*$BIOINFO\_ROOT/prj* directory.

Thanks to direnv, each time you `cd` into the project directory you will 
automatically switch to the conda environment of the project and all the 
local executables and libraries will be available in the PATH.

### Downloading Data

In Bioinfoconda, third-party data sets which will be used in potentially 
many different projects are stored in a separate place, the 
*$BIOINFO\_ROOT/data* directory. To make the downloading of the data 
easier, we created the `X-getdata` command, whose syntax is

```
X-getdata URL
```

It supports both http and ftp protocols and is able to download a 
directory recursively, as well as to download only those files which 
match a pattern. Third-party data sets are usually well documented and 
structured, therefore it makes sense to maintain their original 
structure when downloading them; `X-getdata` automatically suggests a 
possible location where to save the downloads: for instance, if the URL 
is http://foo.com/boo/bar/baz.vcf.gz, the suggestion will be 
foo/boo/bar/baz.vcf.gz. If you are not satisfied with the suggestion, 
you can manually override it. Files are downloaded inside the 
*$BIOINFO\_ROOT/data* directory.

##### TODO

To warrant reproducibility we need a way to log for each downloaded file 
its URL and the date when it was downloaded. A possible option is to 
have a simple XML file with the index of the data directory; we should 
then periodically compare the index with the real directory tree so that 
when files are moved or deleted a warning appears (similar to what git 
does). The disadvantage would be that when many files are downloaded the 
comparison can be quite slow. Another possibility is to embed custom 
metadata to the files using setfattr and getfattr; here the drawback 
would be that accessing the data would be perhaps more difficult.

### Working on a Project

First of all, note that bioinfoconda is itself a project in 
bioinfoconda. (We liked the idea of a 'metaproject', which everyone in 
the system could contribute to and improve just like any other data 
analysis project.) After all, the directory can be moved to another 
place, provided that the environment varialbes are changed as well.

When working on a project it is common to require a specific program to 
perform some operations. There are two options: either an existing 
program can be downloaded or a new program is to be written. In the 
former case, the first thing to try is to install it with conda, i.e. 
`conda install -c channel package`. (In a new project, by default the 
only packages installed in the conda environment are snakemake, R and 
perl.) If the package is not contained in conda's repositories, you can 
manually download it by following the maintainer's instructions. Each 
new project is created with a predefined set of subdirectories, and you 
should install your programs in one of those; see below for a 
description of the intended purpose of each subdirectory. Always 
remember to check whether you need to add the executables to the PATH or 
the libraries to your environment. In such cases, you have to edit the 
project's .envrc, located in the project's home, so that direnv is aware 
of your configuration. When you need to write your own program you 
should also put it in one of the project's subdirectories and make sure 
that executables and libraries are added to the environment. An 
important thing is that the shebang should be '#!/usr/bin/env XXX', not 
simply '#!/usr/bin/XXX'.

Each project is created with a specific directory structure, which will 
now be explained. Note, however, that these are just hints, so if you 
think your project would benefit from another structure, feel free to 
adopt it.

Directly under the project's home there are two subdirectories, 
*dataset* and *local*. The former is the one where the actual work is 
done, therefore it will contain the results of the analysis; the latter 
contains all the scripts, configuration files and other project-related 
things, such as the documentation or the draft of a scientific paper. 
Since *local* has many subdirectories of its own, we provide a table to 
describe each of them.

Directory   | Purpose
---         | ---
snakefiles  | snakefiles for snakemake; they are symlinked in *dataset* 
dockerfiles | dockerfile which can be symlinked in the project's home
ymlfiles    | conda yml file with the list of programs in the environment
config      | config files for snakemake and other config files
src         | sources of programs written by you or downloaded
bin         | symlinks to the executables of programs whose source is in src
lib         | programs that are not executed but that contain functions called by other programs
builds      | used to builds programs from source
data        | data sets that are used only for that project
doc         | documentation, draft of the paper

### Example

In order to fix these ideas, let us see an example. Say we want to 
analyse the genome of some microbes that our colleague has just 
sequenced: we will map the reads to a reference genome and then call the 
variants.

**Creating the project** To create the project, we run `X-mkprj 
microbe-genome-analysis`; now we have a directory structure and a conda 
environment, so we enter the project directory with `cd 
$BIOINFO_ROOT/prj/microbe-genome-analysis`. We are faced with two 
directories, dataset and local, and we enter dataset, where we find a 
Snakefile -- we like Snakemake so it is the default workflow manager, 
but any alternative will work.

**Downloading data** First of all, we need the data. Suppose the 
reference genome for the organism we are interested in is at 
https://microbe-genomes.com/downloads/vers_0.5/genome.fa: we simply run 
`X-getdata https://microbe-genomes.com/downloads/vers_0.5/genome.fa` to 
download the sequence, which will be saved at 
*$BIOINFO_ROOT/data/microbe-genomes/vers_0.5/genome.fa*.

Then we need the sample data. While the reference genome can be useful 
in general for many different projects, the sample data is specific to 
our own project, therefore we download it in 
*local/data/samples/A.fastq*. In general, We may use wget or curl to 
download remote files, or simply put them in local/data if we have a 
local copy of the files.

**Writing the workflow** The snakefile is actually a symbolic link to a 
file in local/snakefiles. Indeed, we separate scripts and configuration 
files (which are in local) from results (which are in dataset).

Following the [snakemake 
tutorial](https://snakemake.readthedocs.io/en/stable/tutorial/basics.html), 
we edit the snakefile and write:

```
rule bwa_map:
    input:
        "$BIOINFO_ROOT/data/microbe-genomes/vers_0.5/genome.fa",
        "$BIOINFO_ROOT/prj/microbe-genome-analysis/local/data/samples/A.fastq"
    output:
        "mapped_reads/A.bam"
    shell:
        "bwa mem {input} | samtools view -Sb - > {output}"
```

**Getting software -- conda** At this stage we still don't have the bwa 
and samtools programs, so we need to download them. The first thing to 
do is a search in anaconda repositories to see whether bwa is packaged; 
it turns out that it is and we can install it with `conda install -c 
bioconda bwa`. A very useful site is [anaconda 
cloud](https://anaconda.org), which not only lets you search anaconda 
packages, it also tells you which command to run if you want to install 
it (check for instance the [samtools 
page](https://anaconda.org/bioconda/samtools)).

**Getting software -- manual compilation** Similarly, samtools is 
packaged in anaconda repositories, so we could install it as easily as 
`conda install -c bioconda samtools`; nevertheless, for the sake of this 
example, let us install it manually. We browse the web and find the 
samtools page at http://www.htslib.org/download/; we want to download 
the source code in the project's local/src, then install samtools under 
local/builds, and finally copy the binary files in local/bin. We run:

```
cd $BIOINFO_ROOT/prj/microbe-genome-analysis/local/src
wget https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2
tar -xf samtools-1.9.tar.bz2
```

Then, following the instructions at the download page, we run

```
cd samtools-1.9
mkdir $BIOINFO_ROOT/prj/microbe-genome-analysis/local/builds/samtools-1.9
./configure --prefix=$BIOINFO_ROOT/prj/microbe-genome-analysis/local/builds/samtools-1.9
make
make install
```

We probably will need to download additional dependencies such as 
ncurses and bzip2. Always try to install them with conda; install them 
manually only as a last resort.

We are nearly done: we have our source code in local/src/samtools-1.9 
and the built program in local/builds/samtools-1.9. It is good practice 
to have each program in its own directory (at least if the program is 
large... 30-line scripts may not deserve their own directory). Under 
local/builds/samtools-1.9 there is a bin directory with all the 
executables, so the only thing we need now is to add this directory to 
our PATH environmental variable. If we install many packages, we need to 
add many entries to the PATH. The recommended way to add some 
executables to the PATH, however, is not to alter the PATH variable: 
instead, we symlink them in the global bin directory, so that all the 
executables will be in one place. The project's local/bin directory is 
already in our PATH, therefore we just run

```
ln -s local/builds/bin/\* local/bin/
```

To recap, the steps of manual compilation are: download the source code 
in local/src/program\_name, configure it with the option --prefix 
local/builds/program\_name, build it by running `make` and `make 
install`, and finally symlink the executables to local/bin.

We are now ready to run our first snakemake rule, so we come back to the 
dataset directory and run

```
snakemake mapped_reads/A.bam
```

If everything worked well, we should now have some results under dataset 
while all the files we used to get those results are under local; by the 
way, this separation of results from the rest makes it easier to backup 
only the important things since the results can be easily obtained by 
re-running all the workflow. Remember that if you will export this 
project to another machine, manually installed modules like samtools 
will have to be rebuilt! This is why using conda is so much better.

**Getting software -- installing libraries** Now suppose we find an 
excel with microbe data, which we download under local/data/extra, and 
we want to parse it to enrich our analysis. We shall provide first an 
example of how to download a Perl module, Spreadsheet::ParseExcel. Its 
location should be under local/lib/perl5 (recall that by library we mean 
a program which is not executed directly but it is called from other 
perl scripts). Again, first we search anaconda cloud for a packaged 
version; luckily we find it, so we can run `conda install -c biobuilds 
perl-spreadsheet-parseexcel`. However, for the sake of this example, we 
will not do it; instead, we are going to install it manually. For perl 
modules, there are actually three options: (a) the first is to download 
the source code under local/src/Spreadsheet-ParseExcel and then compile 
it with `perl Makefile.PL INSTALL_BASE=local/lib/perl5`; (b) 
alternatively, we could use `cpan install Spreadsheet-ParseExcel`; (c) 
the best option, however, is to use cpanm.

Method (a) is annoying because if the module has many dependencies we 
have to manually install each of them. CPAN (method (b)) is more 
convenient, but it has to be configured for each user individually, 
which is somehow unpleasant. The third option, CPANM, is the recommended 
one: it is as powerful as CPAN, but there is virtually no configuration 
to make; moreover, bioinfoconda supports it and makes sure that when you 
run `cpanm module` from inside the project directory, the module source 
is downloaded under local/src, built under local/builds/cpanm and 
installed under local/lib/perl5.

From the above discussion we can extract a general recommendation: when 
installing the interpreter of a programming language such as Perl, we 
should install the associated package manager as well. In this case, 
since we use Perl, we install perl and cpanminus. For instance, if we 
program in Node.js we would install node and npm. Of course when we say 
install we actually mean `conda install`.

For python modules, it suffices to run `pip install modulename`; they 
are handled by conda itself. For R modules (after making sure that the 
package is not in conda), just run R at the console and type 
`install.package("pkgname")`; if it is a bioconductor package, type

```
source("http://bioconductor.org/biocLite.R")
biocLite()
biocLite(c("pkgname1", "pkgname2"))
```

This should cover most common cases; if you cannot install your module 
in any of those ways, probably you had better write your own library :) 

**Getting software -- writing it** Now that we have our module, we can 
start writing our own script to parse the excel file. We start editing 
the file local/src/parse\_microbe\_samples.pl:

```
#!/usr/bin/env perl

use strict;
use warnings;
use Spreadsheet::ParseExcel;

...
```

Note first that we used a special shebang and secondly that we do not 
need to specify the local lib directory where we downloaded the 
Spreadsheet module: bioinfoconda takes care of that. Indeed, thanks to 
direnv, when we work at this project the environment variable PERL5LIB 
is set to local/lib/perl5. (for other programming language it works 
similarly.) When we are done we should make sure that this script is in 
the PATH environment variable, so we simply link it under 
local/bin/parse_microbe_sample.

We now come back to the dataset directory and write a second snakerule:

```
rule parse_excel:
    input:
        "$BIOINFO_ROOT/prj/microbe-genome-analysis/local/data/extra/microbe_data.xls"
    output:
        "microbe_data/summary.txt"
    shell:
        "parse_microbe_samples {input} > {output}
```

Note also that we don't need to specify the path to our perl script 
since it is under local/bin and local/bin is in the PATH environment 
variable.

**Running the workflow** TODO

#### Extra: R Studio integration

TODO

### Using Docker

TODO.

#### TODO

* Log everything to journald

* Possibly send mails to bioinfoadmin

* Make the names coherent (bioinfo vs bioinfoconda...)

* Improve docker management

* Keep an index of the data

* Config file with default conda packages and default directories

#### FIXME

* If you are inside a project, X-getdata and X-mkprj are not available
