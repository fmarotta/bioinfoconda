#!/bin/bash

# TODO: allow to run outside of an environment (parse -p and -n options)

# TODO: we should parse all the options with optparse and validate them.

# TODO: in the future we might add functionalities to X-conda, for 
# instance X-conda export or X-conda regenerate... In these cases, this 
# script will change a little: it would only parse and validate $1, and 
# call other scripts according to it (for instance X-conda-export.sh). 

# validate the environment
if [[ ! -z "${BIOINFO_ROOT}" ]]; then
        source $BIOINFO_ROOT/bioinfoconda/local/lib/bash/bash_functions
else
	error '${BIOINFO_ROOT} is not defined' 3
fi
if [[ -z "${CONDA_PREFIX}" ]]; then
        error 'You must be inside a conda environment' 3
fi

options=yfmCc:n:p:qkh
longoptions=help

date=$(date +%Y-%m-%d)
prjname=$(basename ${CONDA_PREFIX})
prjpath=${BIOINFO_ROOT}/prj/$prjname
env_file=$prjpath/local/ymlfiles/${date}_${prjname}.yml
history_file=${CONDA_PREFIX}/conda-meta/history

# Usage string
read -r -d '' usage << END
Usage:
        `basename $0` install -c CHANNEL PACKAGE1 PACKAGE2 ...

More in detail:
        `basename $0` install [-y] [--dry-run] [-f] [--no-deps] [-m]
                [-C] [--use-local] [--offline] [--no-pin] [-c CHANNEL]
                [--override-channels] [-n ENVIRONMENT | -p PATH] [-q]
                [--copy] [-k] [--update-dependencies]
                [--no-update-dependencies] [--channel-priority]
                [--no-channel-priority] [--clobber]
                [--show-channel-urls] [--no-show-channel-urls]
                [--download-only] [--json] [--debug] [--verbose]
                [PACKAGE1 [PACKAGE2 [...]]]

Options:
        For an explanation of the options, see the usage of \`conda
        create'.

Notes:
        This program removes and recreate the current conda environment.
        It is the heavy artillery to be deployed when "conda install"
        fails. As specified in the documentation of conda, the
        installation of all the packages at once reduces the chances
        of conflicts.

        If you do not provide any option, the environment will be
        simply regenerated; this might be useful to solve some
        conda-related problems.

Reporting bugs:
	federicomarotta AT mail DOT com
END

# Check syntax and acquire options and arguments
if [[ $# -eq 0 ]] || [ $1 != "install" ]; then
        error "$usage" 1
fi
argv="${@:2}"

PARSER=$(getopt --options=$options --longoptions=$longoptions --name "$0" -- "$@")
eval set -- "$PARSER"

while true; do
	case "$1" in
		-h|--help )
			echo "$usage"
			exit 0
			;;
                -- )
			shift
			break
			;;
		* )
                        # For now we do not exclude any argument
                        shift
			;;
	esac
done

# Export the environment as it is now
conda env export -n $prjname -f $env_file

# Get a list of channels and update_specs
info "Getting the channels and packages of the environment..."
channels="-c $(X-conda-get-channels -f $env_file | sed 's/ / -c /g')"
specs=$(X-conda-get-specs -f $history_file)

# Recreate the environment
info "Deactivating environment..."
source deactivate

info "Running: conda env remove -n $prjname"
conda env remove -y -n $prjname

info "Running: conda create --name $prjname $channels $argv $specs"
conda create --name $prjname $channels $argv $specs

if [[ $? -eq 0 ]]; then
        info "Reactivating environment..."
else
        error "Sorry, that did not work." 9
        exit 9
fi

source activate $prjname
info "All done."
