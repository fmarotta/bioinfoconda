# Bioinfoconda

A modern, flexible framework for medium-size data analysis projects, 
based on Conda environments and easily exportable to Docker images.

## Installation Instructions (Linux only)

1. Clone this repository; if you want a system-wide installation and 
   have root permissions, you can install it for instance directly under 
/, while if you are an unprivileged user you can install it under your 
home directory.

```
git clone --recurse-submodules https://github.com/fmarotta/bioinfoconda
```

2. Install Miniconda (you can install it in any path, but if you want to 
   have everything in a place, install it under bioinfoconda)

```
follow the instructions 
[here](https://conda.io/docs/user-guide/install/index.html)
```

3. Install direnv (if you do not have rootly powers, you can install it 
   under bioinfoconda, otherwise there probably is a packaged version 
for your system)

```
see [here](https://github.com/direnv/direnv) for the instructions
```

4. (Optional) Install Docker

```
instructions [here](https://docs.docker.com/install/)
```

5. Set up the environment
        * Add bioinfoconda's executables to your PATH
        * Add bioinfotree's executables to your PATH
        * Add miniconda's executables to your PATH
        * Add bioinfotree's python and perl libraries to the environment
        * Set BIOINFO_ROOT
        * Make sure you have LC_ALL set
        * Configure the bashrc so that direnv works

6. (Useful in a multi-user system) Create a "bioinfoconda" group and fix 
   the directory permissions (then add the users supposed to use 
bioinfoconda to the "bioinfoconda" group)

```
sudo addgroup bioinfoconda
sudo chown -R root:bioinfoconda $BIOINFO_ROOT
sudo chmod -R 2775 $BIOINFO_ROOT
```

-----

Step 5., which is probably the one that requires most work, translates 
into appending the following to the *.bashrc*'s of all the users of 
bioinfoconda

```
# Bioinfoconda configuration
# ----------------------------------------------------------------------

# Export environment variables
export PATH="/bioinfoconda/bioinfotree/local/bin:/bioinfoconda/prj/bioinfoconda/bin:/bioinfoconda/miniconda/bin:$PATH"
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
over him/her), you could also put the environment variables in 
*/etc/environment* and append the other instructions to 
*/etc/skel/.bashrc*, so that the configuration will be available to all 
users.

Remember to edit the previous instructions according to your 
requirements and taste (for instance, you could need to change the path 
names).

## Usage Instructions

### Creating Projects

To create a new project, simply run

```
X-mkprj PROJECT_NAME
```

TODO.

### Downloading Data

TODO.

### Using Docker

TODO.
