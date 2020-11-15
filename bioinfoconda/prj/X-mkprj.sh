#!/bin/bash

# trap ctrl-c and call clean_prj()
trap clean_prj INT

# validate the environment
if [[ -z "${BIOINFO_ROOT}" ]]; then
    error '${BIOINFO_ROOT} is not defined' 3
fi

source $BIOINFO_ROOT/bioinfoconda/lib/bash/bash_functions

if which conda > /dev/null; then
    minicondapath=$(conda info --base)
fi
bioinfotreepath="$BIOINFO_ROOT/bioinfotree"
gitlab_config_file="$BIOINFO_ROOT/bioinfoconda/gitlab/gitlab_config"
templatespath="$BIOINFO_ROOT/bioinfoconda/templates"
date=$(date +%Y-%m-%d)

options=hTGLCir
longoptions=help,no-templates,no-git,no-gitlab,no-conda,interactive-conda,remove


# Usage string
read -r -d '' usage << END
Usage: `basename $0` [options] prjname

Options:
    -T|--no-templates       do not create template Snakefile and
                            Dockerfile.
    -G|--no-git             do not initialise local git repository
                            (implies -L)
    -L|--no-gitlab          do not create remote repository on GitLab.
    -C|--no-conda           do not create the conda environment.
    -i|--interactive-conda  enable the creation of a customised conda
                            environment.
    -r|--remove             remove project directory and conda
                            environment.
    -h|--help               print this message.

Notes:
    This program does the following things:
    1) Creating a directory structure for the project.
    2) Adding default Dockerfile and Snakefile.
    3) Initialising a git repository, both locally and on GitLab.
    4) Creating a conda environment.
    5) Setting up direnv for project environment and libraries.

    With the \`-i' option, you will be prompted to choose the channels
    and packages that will be added initially to the conda environment;
    otherwise the environment will contain R, perl, cpanm and snakemake.
    Use this option only if you know what you are doing.

    By default, `basename $0` tries to create a remote repository on
    GitLab, but this feature requires some configuration before it can
    be used. In particular, you should first create an account on
    GitLab, then create a group owned by that account, and finally
    obtain an API token. See the documentation for the detailed
    instructions.

    To remove a project, use the \`-r' option and provide the
    project name. The entire directory of the project, as well as
    the related conda environment and the GitLab repository, if they
    exists, are eliminated. If you also pass the -L option, the remote
    GitLab repository is not deleted. With -C, the conda environment
    is not removed.

Reporting bugs:
    federicomarotta AT mail DOT com
END

# Functions definition
function clean_prj()
{
    prjpath=$1
    prjname=$(basename $prjpath)
    gitlab_username=$( awk '(NR == 2) {print $1}' $gitlab_config_file )
    gitlab_group_id=$( awk '(NR == 2) {print $2}' $gitlab_config_file )
    gitlab_token=$( awk '(NR == 2) {print $3}' $gitlab_config_file )

    # Remove local directory
    if [ -d $prjpath ]; then
        rm -rf $prjpath
    fi

    # Remove conda environment
    if ((conda)); then
        if conda info --envs | grep "^$prjname[[:space:]]" > /dev/null; then
            conda env remove -y -n $prjname
        fi
    fi

    # Remove remote gitlab repository
    if ((gitlab)); then
        # Check for invalid gitlab configuration
        if [ -z "$gitlab_username" ] || [ -z "$gitlab_group_id" ] || [ -z "$gitlab_token" ]; then
            echo "Invalid gitlab configuration. This feature requires you to provide some configuration parameters; check the documentation for help."
            return 4
        fi

        response=$( curl -s --header "Private-Token: $gitlab_token" \
            -X DELETE "https://gitlab.com/api/v4/projects/$gitlab_username%2F$prjname" )

        if [ "$?" != "0" ]; then
            echo "curl had some problems to send your request."
            return $?
        fi
        if [ "$response" != '{"message":"202 Accepted"}' ]; then
            echo "The GitLab API complained about your request:"
            echo $response
            return 8
        fi
    fi

    return 0
}
function is_valid_name()
{
    re='^[0-9a-z_-]+$'
    if [[ $1 =~ $re ]] ; then
        return 0
    else
        return 1
    fi
}
function sed_template()
{
    template=$1

    sed -e "s#{{prjname}}#$prjname#g" \
        -e "s#{{prjpath}}#$prjpath#g" \
        -e "s#{{minicondapath}}#$minicondapath#g" \
        -e "s#{{bioinfotreepath}}#$bioinfotreepath#g" \
        -e "s#{{BIC_ROOT}}#$BIOINFO_ROOT#g" \
        $template
}
function make_dirs()
{
    prjpath=$1

    mkdir -p $prjpath/dataset \
        && mkdir -p $prjpath/local/{R,benchmark,bin,builds,config,data,doc,dockerfiles,lib,log,python,snakefiles,src,tmp,condafiles} \
        && mkdir -p $prjpath/local/lib/{perl5,python,R} \
        && mkdir -p $prjpath/local/doc/{report,paper} \
    || return $?

    configure_direnv_local $prjpath

    return 0
}
function create_templates()
{
    prjpath=$1
    prjname=$(basename $prjpath)

	# Snakemake templates
    cp $templatespath/Snakefile $prjpath/local/snakefiles/main.smk
    cp $templatespath/latex.smk $prjpath/local/snakefiles/
    sed_template $templatespath/snakemake_config.yml > $prjpath/local/config/snakemake_config.yml

	# Docker templates
    sed_template $templatespath/Dockerfile > $prjpath/local/dockerfiles/Dockerfile
    sed_template $templatespath/docker-entrypoint.sh > $prjpath/local/dockerfiles/docker-entrypoint.sh
    cp $templatespath/dockerignore $prjpath/local/dockerfiles/dockerignore

	# Rmarkdown templates
    sed_template $templatespath/notebook.Rmd > $prjpath/local/doc/report/notebook.Rmd

	# Editorconfig
	cp $templatespath/editorconfig $prjpath/.editorconfig

	# Symbolic links
    ln -s ../local/snakefiles/main.smk $prjpath/dataset/Snakefile
    ln -s local/dockerfiles/dockerignore $prjpath/.dockerignore

    return 0
}
function initialise_repo()
{
    prjpath=$1

    git init --shared=group $prjpath > /dev/null || return $?
    cp $templatespath/gitignore $prjpath/.gitignore

    return 0
}
function initialise_gitlab_repo()
{
    prjpath=$1
    prjname=$(basename $prjpath)
    gitlab_username=$( awk '(NR == 2) {print $1}' $gitlab_config_file )
    gitlab_group_id=$( awk '(NR == 2) {print $2}' $gitlab_config_file )
    gitlab_token=$( awk '(NR == 2) {print $3}' $gitlab_config_file )

    # Check for invalid configuration
    if [ -z "$gitlab_username" ] || [ -z "$gitlab_group_id" ] || [ -z "$gitlab_token" ]; then
        echo "Invalid gitlab configuration. This feature requires you to provide some configuration parameters; check the documentation for help."
        return 4
    fi

    # Create repository
    response=$( curl -s --header "Private-Token: $gitlab_token" \
        -X POST "https://gitlab.com/api/v4/projects" \
        -d "name=$prjname" | jq -r ".message" )

    if [ "$?" != "0" ]; then
        echo "curl had some problems to send your request."
        return $?
    fi
    if [ "$response" != "null" ]; then
        echo "The GitLab API complained about your request:"
        echo $response
        return 8
    fi

    # Share the project with the group
    response=$( curl -s --header "Private-Token: $gitlab_token" \
        -X POST "https://gitlab.com/api/v4/projects/$gitlab_username%2F$prjname/share" \
        -d "group_id=$gitlab_group_id" \
        -d "group_access=40" | jq -r ".message" )

    if [ "$?" != "0" ]; then
        echo "curl had some problems to send your request."
        return $?
    fi
    if [ "$response" != "null" ]; then
        echo "The GitLab API complained about your request:"
        echo $response
        return 8
    fi

    # Add the remote origins
    cd $prjpath
    git remote add origin "https://gitlab.com/$gitlab_username/$prjname.git"
    git remote add ssh-origin "git@gitlab.com:$gitlab_username/$prjname.git"
    cd $OLDPWD

    return 0
}
function create_default_conda()
{
    prjpath=$1
    prjname=$(basename $prjpath)

    sed_template $templatespath/conda_default_environment.yml > $prjpath/local/condafiles/${prjname}_${date}.yml

    mamba env create -f $prjpath/local/condafiles/${prjname}_${date}.yml \
    && mamba env export -n $prjname -f $prjpath/local/condafiles/${prjname}_${date}.yml \
    || return $?

    # && conda config --file $minicondapath/envs/$prjname/.condarc \
    #     --add channels r \
    #     --add channels conda-forge \
    #     --add channels bioconda \

    configure_direnv_conda $prjpath

    return 0
}
function create_custom_conda()
{
    prjpath=$1
    prjname=$(basename $prjpath)

    echo "Complete the command, then press enter to run it:"
    while read -p "conda create -y --name $prjname " args; do
        if ! mamba create -y --name $prjname $args; then
            echo "That did not work. Please try again:"
        else
            mamba env export -n $prjname -f $prjpath/local/condafiles/${prjname}_${date}.yml
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
    # It is important that the miniconda libraries come last.
    echo ".libPaths( c(.libPaths(), \"$minicondapath/envs/$prjname/lib/R/library\") )" >> $prjpath/.Rprofile
}
function configure_direnv_local()
{
    prjpath=$1

    sed_template $templatespath/envrc > $prjpath/.envrc
    sed_template $templatespath/Rprofile > $prjpath/.Rprofile
}

# check syntax and acquire options and arguments
PARSER=$(getopt --options=$options --longoptions=$longoptions --name "$0" -- "$@")
eval set -- "$PARSER"

templates=1
git=1
gitlab=1
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
            gitlab=0
            shift
            ;;
        -L|--no-gitlab )
            gitlab=0
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
        error "-r is not compatible with any other option (except -l)." 5
    fi
fi
if ! ((git)) && (($gitlab)); then
    warn "The GitLab repository will not be created. Recall that -G implies -L." 5
fi

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
        info "Initialising local git repository..."
    if ! initialise_repo $prjpath; then
        clean_prj $prjpath
        error "Could not initialise git repository." 9
    fi
fi

# create remote gitlab repository
if ((gitlab)); then
    info "Creating remote repository on GitLab..."
    if ! initialise_gitlab_repo $prjpath; then
        warn "Could not create remote repository."
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
