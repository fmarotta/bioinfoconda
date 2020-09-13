# Bioinfoconda

An environment to manage workflows for data analysis projects, based on 
Conda environments and easily exportable to Docker images.

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
	* `git clone https://github.com/fmarotta/bioinfoconda`

2. Install Miniconda (you can install it in any path, but if you want to 
   have everything in a place, install it under bioinfoconda)
    * Follow the instructions [here](https://conda.io/docs/user-guide/install/index.html)

3. Install direnv (if you do not have rootly powers, you can install it 
   under bioinfoconda; there probably is a packaged version for your 
system)
    * See [here](https://github.com/direnv/direnv) for the instructions

4. (Optional) Install Docker
    * Instructions [here](https://docs.docker.com/install/)

5. (Optional) Install Bioinfotree
    * [Bioinfotree](https://bitbucket.org/irccit/bit_public/src/ircc_common/) 
    is a set of bioinformatic tools
    * If you know about Bioinfotree at all, you'll probably also know 
    how to install it

5. Set up the environment
    * Set BIOINFO\_ROOT to the path where you cloned the repository
    * Add bioinfoconda's executables to your PATH
    * Add miniconda's executables to your PATH
    * Make sure you have LC\_ALL set
    * Configure the bashrc so that direnv works
    * Add bioinfotree's executables to your PATH
    * Add bioinfotree's python and perl libraries to the environment

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
export LC_ALL="en_US.utf8"
export BIOINFO_ROOT="/bioinfoconda"
export PATH="$BIOINFO_ROOT/bioinfoconda/bin:/bioinfoconda/miniconda/bin:$PATH"
# If you have bioinfotree add also the following three exports
# export PATH="$BIOINFO_ROOT/bioinfotree/local/bin:$PATH"
# export PYTHONPATH="$BIOINFO_ROOT/bioinfotree/local/lib/python"
# export PERL5LIB="$BIOINFO_ROOT/bioinfotree/local/lib/perl"

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

It supports http, ftp, rsync, and now also ssh protocols, and it is able 
to download a directory recursively, as well as to download only those 
files which match a pattern. Third-party data sets are usually well 
documented and structured, therefore it makes sense to maintain their 
original structure when downloading them; `X-getdata` automatically 
suggests a possible location where to save the downloads: for instance, 
if the URL is http://foo.com/boo/bar/baz.vcf.gz, the suggestion will be 
foo/boo/bar/baz.vcf.gz. If you are not satisfied with the suggestion, 
you can manually override it. Files are downloaded inside the 
*$BIOINFO\_ROOT/data* directory.

For each downloaded file, `X-getdata` creates an entry in a log file, so 
that it will be easy to find out who downloaded a file and from where.

### Working on a Project (simplified)

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
condafiles  | conda yml file with the list of programs in the environment
benchmark	| benchmark of rules, scripts, or whole pipelines
config      | config files for snakemake and other config files
src         | sources of programs written by you or downloaded
bin         | symlinks to the executables of programs whose source is in src
lib         | programs that are not executed but that contain functions called by other programs
builds      | used to builds programs from source
data        | data sets that are used only for that project
R			| R scripts
python		| python scripts
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
typing `conda install -c bioconda samtools`; nevertheless, for the sake 
of this example, let us install it manually. We browse the web and find 
the samtools page at http://www.htslib.org/download/; we want to 
download the source code in the project's local/src, then install 
samtools under local/builds, and finally copy the binary files in 
local/bin. We run:

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

Missing libraries are a very common source of troubles. For instance, 
when compiling a program from within a conda environment it may happen 
that a library is not found in spite of it being installed. If such 
library is installed in the system (*i.e.* under `/usr`) you may fix the 
problem by setting an environmental variable specifying where the 
library is to be found. For instance, if you are compiling a rust 
program and the libz library is not found, but it is installed under 
`/usr/lib/x86_64/`, then you may set the environmental variable 
`RUSTFLAGS=-L/usr/lib/x86_64-linux-gnu`. If you alter some environmental 
variable, you should always make the change permanent by editing the 
.envrc and the dockerfile of your project.

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
`local/bin/parse_microbe_sample`.

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

### Working on a Project (advanced)

Having one conda environment per project is great for small pipelines, 
but as soon as the number of installed packages increases, the 
resolution of the environment starts to become slower than time near a 
black hole. Furthermore, it seems unreasonable to bloat the project 
environment with a package that is needed for just one rule; not to 
mention that for bioconductoR packages the resolution is often 
impossible.

In order to avoid the spaghettification of the brain (a concrete risk 
when waiting for the resolution of an environment), it is recommended to 
create multiple conda environments for each project: one 'main' 
environment with the indispensable tools (e.g. Snakemake, R, Rstudio), 
and then other sub-environments, one for each part of the analysis. 
Users are encouraged to use their best judgement when it comes to 
determining how many parts a project has. But for example, one part 
could be labelled 'alignment,' and it would contain all the software 
required for the alignment; another part could be called 'quality 
control;' yet another could be 'statistical analysis,' or 'plots.' 
Snakemake makes it easy to use the appropriate conda environment for 
each rule: check it out 
[here](https://snakemake.readthedocs.io/en/stable/snakefiles/deployment.html).

#### Best practices

* Always use relative links to access project-related files from within 
the project

#### Extra: R Studio integration

* Install the rstudio package from conda for the project where you need 
it.

* From a directory within the project, run the command `rstudio`. If you 
are working on a remote server, make sure that you connected with `ssh 
-X ...` (the -X option allows the server to forward graphical 
applications like Rstudio to the client).

* Once Rstudio is up, create a project from an existing directory and 
choose the root directory of your project. This will make sure that 
Rstudio knows where to find the libraries and the Rprofile.

### Using Docker for occam

occam, the supercomputer of the University of Turin, is the main 
external cluster used by the bioinfoconda community. (If you use another 
service, such as AWS, and you want to contribute the instructions for 
your favorite platform, by all means make a PR or email the maintainer.)

Using occam is surprisingly difficult and many things are not explained 
in the official documentation. Here we provide a step-by-step guide for 
using occam the Bioinfoconda way. Before starting, however, please make 
sure you have a basic understanding of Docker and occam by reading the 
respective manuals and tutorials.

It is helpful to classify the files that are involved in the pipeline 
into three categories: *input*, *output,* and *intermediate*. To the 
*output* caterogy belong all those files which we need but we don't 
have; ideally there should be a single Snakemake rule (or equivalent) to 
generate all the output files at once. The *intermediate* files are 
those that are automatically generated by Snakemake; we need not worry 
about them. And the *input* files are the ancestors of all the files in 
the analysis; typically they have been obtained by our wet-lab 
colleagues, or downloaded from the internet. Note that *input* does not 
refer to the input section of a single rule, but it refers to the set of 
all files that are not generated by any rule or script; they are the 
files that go in the *local/data* directory of the project, or in the 
*/bioinfo/data*, or even those files that are inside other projects.

Moreover, it is helpful to keep in mind the distinction between: your 
local machine, where you write and run your pipelines on an everyday 
basis; occam, the supercomputer; and the docker container, a virtual 
machine that can run everywhere.

1. Write and test the pipeline on your local machine. Make sure that you 
   can obtain the result that you want by running just one command. For 
   example, if you use Snakemake, make sure that the dependencies are 
   resolved correctly and there is a rule to make everything; if you 
   don't use Snakemake or similar software, you could write a custom 
   script that will execute all the steps in the pipeline. The important 
   thing is that the target file and all its dependencies be created 
   with just one command, starting from a limited set of *input* files.

1. Export the environment by running `X-conda export` (It is good 
   practice to do this every time you install something with conda, but 
   it is mandatory before building the docker image.)

1. There is a default *local/docker/Dockerfile* inside each project, but 
   you will need to do some editing:
   * the ymlfile path must be changed to match the one you have exported 
   in step 2;
   * if you manually created new environmental variables you have to add 
   them to the dockerfile;
   * you may have to incorporate in the Dockerfile other manual changes 
   you did: always think about that.

1. `cd` into the project directory and build the docker image by 
   running:
   ```
   docker build -t "gitlab.c3s.unito.it:5000/user/project_name" -f 
   local/dockerfiles/Dockerfile .
   ```
   Note that the last dot '.' is part of the command. Replace 'user' 
   with your username on occam (not on the local machine) and 
   'project\_name' with an arbitrary name (it helps if it is related to 
   your project's name, like for instance 'alignment\_v2').
   Important: the content of the *dataset* directory is not part of the 
   docker image, therefore, if some of the *input* files are inside 
   *dataset*, you'll need to mount them as volumes; the master 
   Snakefile, in particular, should always be mounted.

1. Test the image locally. There are many things that can be tested, but 
   a basic thing would be to run
   ```
   docker run -it "gitlab.c3s.unito.it:5000/user/project_name"
   ```
   and explore the docker container to see if everything is where it 
   should be. You could also try and mount the volumes (see later steps) 
   and run the snakemake command to create your target.

1. Create a repository on occam's GitLab (see [occam 
   HowTo](https://c3s.unito.it/index.php/super-computer/occam-howto)). 
   It should be called "project\_name" as in the previous step.

1. Push the image to occam registry by running the following two 
   commands:
	```
	docker login "gitlab.c3s.unito.it:5000"
	docker push "gitlab.c3s.unito.it:5000/user/project_name"
	```

1. Log in to [occam website](https://c3s.unito.it/index.php) and Use the 
   [Resource Booking System](https://c3s.unito.it/booked/Web/?) to 
   reserve a slot. You will need to choose which node(s) to reserve and 
   then estimate the time it will take to compute your pipeline using 
   the chosen resources. Tips:
   * If you book 2 light nodes, you don't have 48 cores; you will have 
   to run 2 separate containers, each with 24 cores.
   * The reservation can be updated (or deleted) only before its 
   official start.
   * If you reserve two consecutive time slots for the same machine, the 
   container will not be interrupted.

1. Log in to occam (see the 
   [HowTo](https://c3s.unito.it/index.php/super-computer/occam-howto)) 
   and `cd` into */scratch/home/user/*, then create a directory called 
   *project_name* (it's not important that it be called like that, but 
   it helps).

1. Now it's time for the hard part: docker volumes. You'll have to think 
   of all the *input* files that your target needs. Suppose that, on 
   your local machine, the target is 
   */bioinfo/prj/project_name/dataset/analysis/correlation.tsv*, while
   the *input* files are located under four different directories:
   * */bioinfo/data/ucsc/chromosomes*,
   * */bioinfo/prj/project_name/local/data/annotation*,
   * */bioinfo/prj/otherproject/dataset/expression*,
   * */bioinfo/prj/project_name/dataset/alignments*
   You may need the last directory if, for instance, you have already 
   run the alignment rules on your local machine, and now you just need 
   to compute the correlation, without re-doing the alignment. In this 
   situation, my reccommendation is to do as follows.
   From occam, `cd` into */scratch/home/user/project_name* and create 
   four directories:
   * `mkdir chromosomes`,
   * `mkdir annotation`,
   * `mkdir expression`,
   * `mkdir -p dataset/aligments`.
   Then, use `rsync` (or your favorite equivalent tool) to copy the 
   files from your local machine to occam:
   * `rsync -a user@localmachineIP:/bioinfo/data/ucsc/chromosomes/* chromosomes`
   * `rsync -a user@localmachineIP:/bioinfo/prj/project_name/local/data/annotation/* annotation`
   * `rsync -a user@localmachineIP:/bioinfo/otherproject/dataset/expression/* expression`
   * `rsync -a user@localmachineIP:/bioinfo/prj/project_name/dataset/alignments/* dataset/alignments`
   Lastly, copy the master Snakefile (this has to be done even if you 
   don't mount any volume):
   * `rsync -a user@localmachineIP:/bioinfo/prj/project_name/dataset/Snakefile dataset/`

1. Test the image on occam, mounting all the volumes. In a sense, this 
   step is the opposite of the previous one: in the previous, we 
   **copied** the directories from the local machines to occam, now we 
   **mount** these directories in the docker container, but we mount 
   them at the same paths that they have in the local machine. I suggest 
   to `cd` into */archive/home/user* and create a directory called like 
   the title of the reservation that you have created through occam's 
   resource booking system, and append the current date. For instance, 
   `mkdir projectX_correlation_2020-09-13`. Then, `cd` into the new 
   directory and run:
   ```
   occam-run \
   -v /scratch/home/user/project_name/chromosomes:/bioinfo/data/ucsc/chromosomes \
   -v /scratch/home/user/project_name/annotation:/bioinfo/prj/project_name/local/data/annotation \
   -v /scratch/home/user/project_name/expression:/bioinfo/prj/otherproject/dataset/expression \
   -v /scratch/home/user/project_name/dataset:/bioinfo/prj/project_name/dataset \
   -t user/project_name \
   "snakemake -np target"
   ```
   The above command will start running the container and executing the 
   command to make the target (here assuming that you use snakemake). 
   Please note that the quotes ("") are important. The container will 
   run in occam's node22, which is a management node reserved for 
   testing purposes only, so we cannot run the whole analysis on this 
   node. That's why we use snakemake with the `-n` option. When the 
   above command exits, after a bit you will find three files called 
   something like *node22-5250.log*, *node22-5250.err*, and 
   *node22-5250.done*. Inspect their content and see if everything is 
   OK. In particular, the *.log* file should contain the output of 
   `snakemake -np target`. If something is wrong, try to fix the problem 
   and repeat.

1. When the time of your reservation comes, run the same command as 
   before from the same directory as before, but add the option `-n 
   nodeXX`. For instance, if you reserved node 17, write
   ```
   occam-run \
   -n node17 \
   -v /scratch/home/user/project_name/chromosomes:/bioinfo/data/ucsc/chromosomes \
   -v /scratch/home/user/project_name/annotation:/bioinfo/prj/project_name/local/data/annotation \
   -v /scratch/home/user/project_name/expression:/bioinfo/prj/otherproject/dataset/expression \
   -v /scratch/home/user/project_name/dataset:/bioinfo/prj/project_name/dataset \
   -t user/project_name \
   "snakemake -np target"
   ```

1. Remember that if you have booked multiple nodes, you will need to run 
   `occam-run` multiple times, once for each node. It is up to you to 
   split the targets and mount the volumes appropriately. GOOD LUCK.

#### TODO

* Log everything to journald

* Possibly send mails to bioinfoadmin

* Make the names coherent (bioinfo vs bioinfoconda...)

* Config file with default conda packages and default directories

* Document the templates
