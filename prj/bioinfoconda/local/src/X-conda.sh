#!/bin/bash

source ../lib/bash_functions

read -r -d '' usage << END
Usage: `basename $0` install [options]

Heavy artillery to be deployed when "conda install" leads to conflicts. 
Forces the reinstallation of all the environment's packages at once, 
attempting to ressolve the conflicts.

Reporting bugs:
        federicomarotta AT mail DOT com
END

if [ $1 != "install"]; then
        error "$usage" 1
fi
