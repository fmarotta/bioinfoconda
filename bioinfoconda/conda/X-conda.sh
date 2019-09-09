#!/bin/bash

# TODO: allow to run outside of an environment (parse -p and -n options)

# validate the environment
if [[ ! -z "${BIOINFO_ROOT}" ]]; then
		source $BIOINFO_ROOT/bioinfoconda/lib/bash/bash_functions
else
	>&2 echo 'ERROR: ${BIOINFO_ROOT} is not defined'
	exit 3
fi
if [[ -z "${CONDA_PREFIX}" ]]; then
        error 'You must be inside a conda environment' 3
fi

# Usage string
read -r -d '' usage << END
Usage:
	`basename $0` [-h] command ...

Commands:
	The command can be one of the following:

	* install:	brute-force installation of packages
	* export:	save the environment to a file

Reporting bugs:
	federicomarotta AT mail DOT com
END

# Check syntax and acquire options and arguments
if [[ $# -eq 0 ]]; then
        error "$usage" 1
elif [ $1 == "-h" ]; then
	echo "$usage"
elif [ $1 == "install" ]; then
	X-conda-install "${@:2}"
elif [ $1 == "export" ]; then
	X-conda-export "${@:2}"
else
	error "$usage" 1
fi
