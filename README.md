# Bioinfoconda

A framework for medium-size data analysis projects, based on Conda 
environments and easily exportable to Docker images.

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

### Working on a Project

First of all, note that bioinfoconda is itself a project in 
bioinfoconda. (We liked the idea of a 'metaproject', which everyone in 
the system could contribute to and improve just like any other data 
analysis project.) After all, the directory can be moved to another 
place, provided that the environment varialbes are changed as well.

When working on a project, it is common to require a specific program to 
perform some operations. There are two options: either an existing 
program can be downloaded or a new program is to be written. In the 
former case, the first thing to try is to install it with conda, i.e. 
`conda install package`. (In a new project, by default the only packages 
installed in the conda environment are snakemake, R and perl.) If the 
package is not contained in conda's repositories, you can manually 
download it by following the maintainer's instructions. Each new project 
comes with a predefined set of subdirectories, and you should install 
your programs in one of those; see below for a description of the 
intended purpose of each subdirectory. Always remember to check whether 
you need to add the executables to the PATH or the libraries to your 
environment. In such cases, you have to edit the project's .envrc, 
located in the project's home, so that direnv is aware of your 
configuration. In case where you need to write your own program, you 
should also put it in one of the project's subdirectories and make sure 
that executables and libraries are added to the environment.

Each project is created with a specific directory structure, which will 
now be explained. Note, however, that these are just hints, so if you 
think your project would benefit from another structure, feel free to 
adopt it.

Directly under the project's home there are two subdirectories, 
*dataset* and *local*. The former is the one where the actual work is 
done, therefore it will contain files with each step of the analysis, as 
well as the results; the latter contains all the scripts, configuration 
files and other project-related things, such as the documentation. Since 
*local* has many subdirectories of its own, we provide a table to 
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
data        | data sets that are used only for that project
doc         | documentation, draft of the paper

TODO: practical example

TODO: R Studio integration

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

### Using Docker

TODO.

#### TODO

* Log everything to journald

* Possibly send mails to bioinfoadmin

* Make the names coherent (bioinfo vs bioinfoconda...)

* Improve docker management

* Config file with default conda packages and default directories

#### FIXME

* If you are inside a project, X-getdata and X-mkprj are not available
