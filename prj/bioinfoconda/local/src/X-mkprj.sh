#!/bin/bash

# TODO: edit project name

# TODO: append library paths, don't overwrite them (I don't know if this 
# is actually done or not...)

# DONE: /bioinfo/miniconda3/envs/demo/lib/R/library add miniconda R
# library to .Rprofile, so that it is imported in Rstudio projects

options=hTGCir
longoptions=help,no-templates,no-git,no-conda,interactive-conda,remove

read -r -d '' usage << END
Usage: `basename $0` [options] prjname

Options:
	-T|--no-templates       do not create template Snakefile and Dockerfile.
        -G|--no-git             do not initialise git repository.
        -C|--no-conda           do not create the conda environment.
        -i|--interactive-conda  enable the creation of a customised conda
                                environment.
        -r|--remove             remove project directory and conda environment.
	-h|--help               print this message.

Notes:
        This program does the following things:
	1) Creating a directory structure for the project.
	2) Adding default Dockerfile and Snakefile.
	3) Initialising a git repository.
	4) Creating a conda environment.
        5) Setting up direnv for project environment and libraries.

        With the \`-i' option, you will be prompted to choose the channels
	and packages that will be added initially to the conda environment;
	otherwise the environment will contain R, perl and snakemake. Use
	this option only if you know what you are doing.

Reporting bugs:
	federicomarotta AT mail DOT com
END

# define cleanup functions
function clean_prj()
{
	prjpath=$1
	prjname=$(basename $prjpath)

	if conda info --envs | grep -w $prjname; then
                conda env remove -y -n $prjname
	fi
	if [ -d $prjpath ]; then
		rm -rf $prjpath
	fi
}

# define logging functions
function bug()
{
	>&2 echo "BUG: $1"
	exit 99
}
function error()
{
	>&2 echo "ERROR: $1"

	re='^[0-9]+$'
	if ! [[ $2 =~ $re ]] ; then
		bug "argument to error() is not a number."
	else
		exit $2
	fi
}
function warn()
{
	>&2 echo "WARNING: $1"
}
function info()
{
	>&2 echo "INFO: $1"
}

# define validating functions
function is_valid_name()
{
	re='^[0-9a-z_-]+$'
	if [[ $1 =~ $re ]] ; then
		return 0
	else
		return 1
	fi
}

# define functional functions
function make_dirs()
{
	prjpath=$1

	mkdir -p $prjpath/dataset \
        && mkdir -p $prjpath/local/{bin,src,lib,snakefiles,dockerfiles,ymlfiles,config,doc,data} \
        && mkdir -p $prjpath/local/lib/{perl,python,R} \
	|| return $?

        configure_direnv_local $prjpath

	return 0
}
function create_templates()
{
	prjpath=$1
	prjname=$(basename $prjpath)

        cat <<- END > $prjpath/local/dockerfiles/Dockerfile
	# Use the bioinfoconda parent image
	# NOTE: you should set a version tag!
	FROM cbuatmbc/bioinfoconda

	# Copy the project directory into the container
	# NOTE: remember to add the Snakefiles to the .dockerignore
	COPY . $prjpath

	# Create the conda environment from the yml file
	# NOTE: remember to export the environment before building the image
	RUN conda env create -f $prjpath/local/ymlfiles/$prjname.yml

	# Set up the environment
	ENV PATH="$minicondapath/envs/$prjname/bin:$prjpath/local/bin\$PATH" \\
	    PERL5LIB="$prjpath/local/lib/perl" \\
	    PYTHONPATH="$prjpath/local/lib/python" \\
	    R_PROFILE_USER="$prjpath/.Rprofile" \\
	    CONDA_DEFAULT_ENV="$prjname" \\
	    CONDA_PREFIX="$minicondapath/envs/$prjname"
	WORKDIR $prjpath/dataset
	USER docker:bioinfo

	# Write here the rest of the instructions.

	END

        cat <<- END > $prjpath/.dockerignore
	# Exclude some hidden files
	.gitignore
	.Rproj.user
	.Rhistory
	.envrc
	# Exclude dataset (this speeds up the build time)
	dataset/*
	# Include snakefiles (due to a bug, they must be added individually)
	!dataset/Snakefile
	END

        cat <<- END > $prjpath/local/snakefiles/Snakefile
	# This is a template Snakefile, change it at will

	# Set the config file
	configfile: "../local/config/snakemake_config.yml"

	# Define the final targets: all the others depend on them
	ALL = ["foo.bed", "bar.png"]

	# Run the entire pipeline and copy the files to a mountable directory
	rule docker:
	        input:
	                ALL
	        shell:
	                "cp -R $prjpath/dataset/.?* $prjpath/results"
	END

        cat <<- END > $prjpath/local/config/snakemake_config.yml
	chr:
	        [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22]
	END

        ln -s $prjpath/local/snakefiles/Snakefile $prjpath/dataset/Snakefile \
        || return $?
        ln -s $prjpath/local/dockerfiles/Dockerfile $prjpath/Dockerfile \
        || retrun $?

	return 0
}
function initialise_repo()
{
	prjpath=$1

	git init --shared=group $prjpath > /dev/null || return $?
	echo dataset/* > $prjpath/.gitignore

	return 0
}
function create_default_conda()
{
	prjpath=$1
	prjname=$(basename $prjpath)

	conda create -y --name $prjname -c r -c conda-forge -c bioconda r perl snakemake \
        && conda env export -n $prjname -f $prjpath/local/ymlfiles/$prjname.yml \
	|| return $?

	configure_direnv_conda $prjpath

	return 0
}
function create_custom_conda()
{
	prjpath=$1
	prjname=$(basename $prjpath)

	echo "Complete the command, then press enter to run it:"
	while read -p "conda create -y --name $prjname " args; do
		if ! conda create -y --name $prjname $args; then
			echo "That did not work. Please try again:"
		else
                        conda env export -n $prjname -f $prjpath/local/ymlfiles/$prjname.yml
			echo "Success!"
			break
		fi
	done

	configure_direnv_conda $prjpath

	return 0
}
function configure_direnv_conda()
{
	prjpath=$1
	prjname=$(basename $prjpath)

        echo "source activate $prjname" >> "$prjpath/.envrc"
        echo ".libPaths( c(\"$minicondapath/envs/$prjname/lib/R/library\", .libPaths()) )" >> $prjpath/.Rprofile
}
function configure_direnv_local()
{
	prjpath=$1

        echo "export PATH=$prjpath/local/bin:$PATH" > "$prjpath/.envrc"
        echo "export PERL5LIB=$prjpath/local/lib/perl" >> "$prjpath/.envrc"
        echo "export PYTHONPATH=$prjpath/local/lib/python" >> "$prjpath/.envrc"
        echo "export R_PROFILE_USER=$prjpath/.Rprofile" >> "$prjpath/.envrc"
        echo ".libPaths( c(\"$prjpath/local/lib/R\", .libPaths()) )" > $prjpath/.Rprofile
}

# check syntax and acquire options and arguments
PARSER=$(getopt --options=$options --longoptions=$longoptions --name "$0" -- "$@")
eval set -- "$PARSER"

# parse the options
templates=1
git=1
conda=1
interactive=0
remove=0
while true; do
	case "$1" in
		-h|--help )
			echo "$usage"
			exit 0
			;;
		-T|--no-templates )
			templates=0
			shift
			;;
                -G|--no-git )
			git=0
			shift
			;;
		-C|--no-conda )
			conda=0
			shift
			;;
		-i|--interactive-conda )
			interactive=1
			shift
			;;
                -r|--remove )
                        remove=1
			shift
                        ;;
		-- )
			shift
			break
			;;
		* )
			bug "Unexpected arguments problem."
			;;
	esac
done

# validate the options
if ((remove)); then
        if [[ $templates == 0 || $conda == 0 || $git == 0 || $interactive == 1 ]]; then
                error "-r is not compatible with any other option." 5
        fi
fi

# validate the environment
if [[ -z "${BIOINFO_ROOT}" ]]; then
	error '${BIOINFO_ROOT} is not defined' 3
fi
minicondapath=$(conda info --base)

# parse and validate the arguments
if [[ $# -eq 1 ]]; then
	if ! is_valid_name $1; then
		error "Project name is not valid. Only lowercase letters, numbers, dashes and underscores are allowed." 5
	fi
        if ((remove)); then
                if ! [ -e ${BIOINFO_ROOT}/prj/$1 ]; then
                        error "This project does not exist." 7
                fi
        else
                if [ -e ${BIOINFO_ROOT}/prj/$1 ]; then
                        error "A project with this name already exists." 7
                fi
	fi
	prjpath=${BIOINFO_ROOT}/prj/$1
else
	error "$usage" 1
fi

# start the script

# Remove a project
if ((remove)); then
        prjname=$(basename $prjpath)

        echo "Are you sure you want to remove project \"$prjname\"? Choose y/n."
        echo "y) Yes, get rid of it!    n) No, wait! Let me reconsider..."

        while read answer; do
                case ${answer:0:1} in
                        'y'|'Y' )
                                echo
                                info "Removing project $prjpath..."
                                echo
                                clean_prj $prjpath
                                info "All done. The project no longer exists."
                                break
                                ;;
                        'n'|'N'|'' )
                                echo
                                info "OK, the project is safe. Bye"
                                break
                                ;;
                        * )
                                echo -n "Please answer yes or no. Try again: [yes/no] "
                                ;;
                esac
        done

        exit
fi

# Otherwise create a project
info "Creating project at $prjpath..."

# make directories
if ! make_dirs $prjpath; then
	clean_prj $prjpath
	error "Could not create directories." 9
fi

# add links to dockerfiles and snakefiles
if ((templates)); then
	info "Adding templates for Dockerfile and Snakefile..."
	if ! create_templates $prjpath; then
		clean_prj $prjpath
		error "Could not create links to templates." 9
	fi
fi

# initialise a git repository
if ((git)); then
	info "Initialising git repository..."
	if ! initialise_repo $prjpath; then
		clean_prj $prjpath
		error "Could not initialise git repository." 9
	fi
fi

# create a conda environment
if ((conda)); then
	info "Starting the creation of a conda environment..."

	if ! ((interactive)); then
		if ! create_default_conda $prjpath; then
			clean_prj $prjpath
			error "Could not create conda environment." 9
		fi
	else
		echo "Do you want to create a custom conda environment? Choose y/n."
		echo "y) create custom environment           n) accept default"

		while read answer; do
			case ${answer:0:1} in
				'y'|'Y' )
					if ! create_custom_conda $prjpath; then
						clean_prj $prjpath
						error "Could not create conda environment." 9
					fi
					break
					;;
				'n'|'N'|'' )
					if ! create_default_conda $prjpath; then
						clean_prj $prjpath
						error "Could not create conda environment." 9
					fi
					break
					;;
				* )
                                        echo -n "Please answer yes or no. Try again: [yes/no] "
					;;
			esac
		done
	fi
fi

# whitelist directory for direnv
direnv allow "$prjpath"

info "All done. New project is at $prjpath"
exit
