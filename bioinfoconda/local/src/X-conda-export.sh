#!/bin/bash

source $BIOINFO_ROOT/bioinfoconda/local/lib/bash/bash_functions

# Usage string
read -r -d '' usage << END
Usage:
	X-conda export

Options:
	-h		Prints this help

Notes:
	The environment is exported in the local/ymlfiles of the project
	and the files are ordered by name and exportation date.

Reporting bugs:
	federicomarotta AT mail DOT com
END

# Validate environment and define defaults
if [[ -z "${CONDA_PREFIX}" ]]; then
        error 'You must be inside a conda environment' 3
fi

options=h
longoptions=help

date=$(date +%Y-%m-%d)
prjname=$(basename ${CONDA_PREFIX})
prjpath=${BIOINFO_ROOT}/prj/$prjname
env_file=$prjpath/local/ymlfiles/${prjname}_${date}.yml

# Parse the options
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
			error "Unexpected arguments. $usage" 3
			shift
			;;
	esac
done

# Start the real script
info "Exporting environment..."
conda env export -n $prjname -f $env_file

if [[ $? == 0 ]]; then
	info "Done. The environment file is $env_file."
else
	error "Something went wrong" $?
fi
