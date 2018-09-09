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
    * Add bioinfoconda's executables to your PATH
    * Add bioinfotree's executables to your PATH
    * Add miniconda's executables to your PATH
    * Add bioinfotree's python and perl libraries to the environment
    * Set BIOINFO\_ROOT to the path where you cloned the repository
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
export PATH="/bioinfoconda/bioinfotree/local/bin:/bioinfoconda/prj/bioinfoconda/local/bin:/bioinfoconda/miniconda/bin:$PATH"
export PYTHONPATH="/bioinfoconda/bioinfotree/local/lib/python"
export PERL5LIB="/bioinfoconda/bioinfotree/local/lib/perl"
export BIOINFO_ROOT="/bioinfoconda"
export LC_ALL="en_US.utf8"

# Configure direnv
eval "$(direnv hook bash)"

# Show conda environment in prompt
# NOTE: with direnv the prompt is not updated properly, so we need this 
to recover the functionality.
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
users.

Remember to edit the previous instructions according to your 
requirements and taste (for instance, you could need to change the path 
names; also make sure not to override any environmental variable which 
was already set for your system).

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
you can manually override it. Files are downloaded inside the data 
directory.

### Working on a Project

TODO.

### Using Docker

TODO.
