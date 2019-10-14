#!/bin/bash

# TODO: add the other conda options to the options string

# Validate the environment
if [[ ! -z "${BIOINFO_ROOT}" ]]; then
	source $BIOINFO_ROOT/bioinfoconda/lib/bash/bash_functions
else
	>&2 echo 'ERROR: ${BIOINFO_ROOT} is not defined'
	exit 3
fi
if [[ -z "${CONDA_PREFIX}" ]]; then
	error 'You must be inside a conda environment' 3
fi

date=$(date +%Y-%m-%d)
minicondapath=$(conda info --base)
prjname=$(basename ${CONDA_PREFIX})
prjpath=${BIOINFO_ROOT}/prj/$prjname
argv=$@

# Usage string
read -r -d '' usage << END
Usage:
    X-conda install -c CHANNEL PACKAGE1 PACKAGE2 ...

Options:
    As of now, only -h|--help and -c|--channel are supported; please
    report a bug if you see the message: "unrecognized option".

Notes:
    This program is simply a wrapper around the regular conda, but it
    allows to painlessly use conda metachannel without having to think
    about the channel url.

    In addition to the regular conda, X-conda install also exports the
    environment after the installation.

Examples:
    1) X-conda install -c r "r-essentials>=3.5.1"
       Will be translated to:
       conda install -c https://metachannel.conda-forge.org/r/r-essentials r-essentials>=3.5.1

    2) X-conda install -c conda-forge -c bioconda keras snakemake==5.6.0
       Will be translated to:
       conda install -c https://metachannel.conda-forge.org/conda-forge,bioconda/keras,snakemake keras snakemake==5.6.0

Reporting bugs:
    federicomarotta AT mail DOT com
END

options=c:h
longoptions=channel:,help
PARSER=$(getopt --options=$options --longoptions=$longoptions --name "$0" -- "$@")
eval set -- "$PARSER"

while true; do
    case "$1" in
		-h|--help )
			echo "$usage"
			exit 0
			;;
		-c|--channel )
			shift
			channels+=("$1")
			;;
		-- )
			shift
			break
			;;
		* )
            # Save all the other options to pass them to conda
            # (This will work when the other options will be added to 
            # the options string)
            opts+=("$1")
			;;
	esac
	shift
done

# Parse the command line options to obtain the list of channels and 
# packages
for p in "$@"; do
    constraints+=($(echo "$p" | sed 's/[<>!= ].*//'))
done
constraints=$(echo "${constraints[@]}" | sed 's/ /,/g')
channels=$(echo "${channels[@]}" | sed 's/ /,/g')

# Install using metachannel
conda install \
	"${opts[@]}" \
	-c "https://metachannel.conda-forge.org/$channels/$constraints" "$@"

# Export the environment with the new package
X-conda-export

info "All done."
