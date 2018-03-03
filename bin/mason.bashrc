

function mason_list()
{
    echo  'ENVIRONMENTS:'
    # list environments
    local i=1
    for d in $ENVIRONMENTS_HOME/*/; do
        d=${d%*/}
        echo "  [$i] ${d##*/}"
        ((i = i + 1))
    done
}


function mason_switch()
{
    mason_list
    echo
    # read user input
    echo -n "Choose environment [#]: "
    read -n 1 choice
    echo
    local i=1
    for d in $ENVIRONMENTS_HOME/*/; do
        d=${d%*/}
        if [ $i -eq $choice ]; then
            mason_load ${d##*/}
            break
        fi
        ((i = i + 1))
    done
}


function mason_load()
{
    local env_name=$1
    local switch=$2
    if [ "x$env_name" == "x" ]; then
        mason_usage
        return 1
    fi
    if [ ! -e $ENVIRONMENTS_HOME/$env_name/env.bashrc ]; then
        echo "Environment \"$env_name\" not found."
        return 1
    fi
    if [ "$switch" != "" ]; then
        if [ "$switch" == "--quiet" ]; then
            : # allgood
        else
            echo "Unknown option '$switch'."
        fi
    fi

    # we used to say hello when loading an environment
    # obsolete since we introduced a named prompt
    #else
    #    echo
    #    echo "Loading $env_name."
    #fi

    local env_file=$ENVIRONMENTS_HOME/$env_name/env.bashrc

    # this is still to be discussed: not quite sure whether the best way
    # is just to source the environment. In future, we may change the startup
    # such that a complete new shell instance is created..

    source $env_file

    # obsolete:
    # bash --rcfile <(echo ". ~/.bashrc; source $env_file")

    # obsolete since we switched to a named prompt
    #if [ "$switch" != "" ]; then
    #    if [ "$switch" == "--quiet" ]; then
    #        : # allgood
    #    fi
    #else
    #    echo "Done."
    #fi
}

# rsync is way faster than 'rm -rf'
function mason_delete_folder()
{
    local cwd=$(pwd)
    local target=${1%/}
    cd $target
    cd ..
    mkdir -p .FAST_DELETE_EMPTY
    rsync -a --delete .FAST_DELETE_EMPTY/ $target/
    rmdir .FAST_DELETE_EMPTY
    rmdir $1
    cd $cwd
}

function mason_remove()
{
    local env_name=$1
    if [ "x$env_name" == "x" ]; then
        mason_usage
        return 1
    fi
    if [ ! -e $ENVIRONMENTS_HOME/$env_name ]; then
        echo "Environment \"$env_name\" not found."
        return 1
    fi
    echo "Removing environment $env_name."
    # fast delete
    mason_delete_folder "$ENVIRONMENTS_HOME/$env_name"
    echo "Done."
}


function mason_install_gravel()
{
    local env_name=$1
    local env_dir="$ENVIRONMENTS_HOME/$env_name"
    local gravel_script=$2

    if [ "x$env_name" == "x" ]; then
        mason_usage
        return 1
    fi
    if [ ! -e $env_dir/env.bashrc ]; then
        echo "Environment \"$env_name\" not found."
        return 1
    fi
    if [ ! -e $gravel_script ]; then
        echo "Gravel script \"$gravel_script\" not found."
        return 1
    fi

    # get gravel folder from gravel script name
    local platform=$(uname)
    if [[ "$platform" == 'Darwin' ]]; then
        local gravel_home=$(dirname $(realpath $gravel_script))
    elif [[ "$platform" == 'Linux' ]]; then
        local gravel_home=$(dirname $(readlink -f -- $gravel_script))
    else
        echo 'Platform $platform not supported!'
        return 1
    fi

    # just to be sure, we remember the path here...
    # this may also be taken care of by the gravel script
    cwd=$(pwd)
    source $gravel_script "$env_name" "$env_dir" "$gravel_home"
    cd $cwd
}

function mason_install()
{
    local first_argument=$(basename "$1")
    local extension="${first_argument##*.}"
    if [ "$extension" == "mason" ]; then
        if [ "x$CURRENT_ENVIRONMENT" == "x" ]; then
            echo "No environment loaded: Please load/provide environment!"
            return 1
        fi
        mason_install_gravel $CURRENT_ENVIRONMENT "$1"
        return 0
    else
        mason_install_gravel "$1" "$2"
        return 0
    fi
}


function mason_edit()
{
    local env_name=$1
    if [ "x$env_name" == "x" ]; then
        env_name=$CURRENT_ENVIRONMENT
        if [ "x$env_name" == "x" ]; then
            mason_usage
            return 1
        fi
    fi
    local ENV_FILE=$ENVIRONMENTS_HOME/$env_name/env.bashrc
    if [ ! -e $ENV_FILE ]; then
        echo "Environment \"$env_name\" not found."
        return 1
    fi

    # try sublime first
    alias subl 2>/dev/null >/dev/null && $(subl --new-window $ENV_FILE) && return 1

    # fallback to vim
    vi $ENV_FILE
}


function mason_toggle()
{
    # Save current state
    TMP_CURRENT_ENVIRONMENT=$CURRENT_ENVIRONMENT
    TMP_PATH=$PATH
    TMP_PYTHONPATH=$PYTHONPATH
    TMP_MANPATH=$MANPATH
    TMP_INFOPATH=$INFOPATH
    TMP_C_INCLUDE_PATH=$C_INCLUDE_PATH
    TMP_LIBRARY_PATH=$LIBRARY_PATH
    TMP_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
    TMP_PS1=$PS1

    # Reload previous state
    export CURRENT_ENVIRONMENT=$MASON_PREV_CURRENT_ENVIRONMENT
    export PATH=$MASON_PREV_PATH
    export PYTHONPATH=$MASON_PREV_PYTHONPATH
    export MANPATH=$MASON_PREV_MANPATH
    export INFOPATH=$MASON_PREV_INFOPATH
    export C_INCLUDE_PATH=$MASON_PREV_C_INCLUDE_PATH
    export LIBRARY_PATH=$MASON_PREV_LIBRARY_PATH
    export LD_LIBRARY_PATH=$MASON_PREV_LD_LIBRARY_PATH
    export PS1=$MASON_PREV_PS1

    # Save previous state
    export MASON_PREV_CURRENT_ENVIRONMENT=$TMP_CURRENT_ENVIRONMENT
    export MASON_PREV_PATH=$TMP_PATH
    export MASON_PREV_PYTHONPATH=$TMP_PYTHONPATH
    export MASON_PREV_MANPATH=$TMP_MANPATH
    export MASON_PREV_INFOPATH=$TMP_INFOPATH
    export MASON_PREV_C_INCLUDE_PATH=$TMP_C_INCLUDE_PATH
    export MASON_PREV_LIBRARY_PATH=$TMP_LIBRARY_PATH
    export MASON_PREV_LD_LIBRARY_PATH=$TMP_LD_LIBRARY_PATH
    export MASON_PREV_PS1=$TMP_PS1

    # Rehash for new paths
    hash -r
}


function mason_modify_usage()
{
    cat <<EOF
MODIFY:
  mason modify                                        --show this help
  mason modify ENVIRONMENT addpath PATH --front       --add path at front
  mason modify ENVIRONMENT addpath PATH --back        --add path at back (default)
  mason modify ENVIRONMENT addlib PATH                --add LIBRARY_PATH at back
  mason modify ENVIRONMENT addsharedlib PATH          --add LD_LIBRARY_PATH at back
  mason modify ENVIRONMENT addpythonpath PATH         --add PYTHONPATH at back
  mason modify ENVIRONMENT export NAME VALUE          --export environment variable
EOF
}

function mason_replace()
{
    local env_file=$1
    local before=$2
    local after=$3
    perl -p -i -e "s&$before&$after&g" $env_file
}


function mason_match_line()
{
    local file=$1
    local match=$2
    perl -ne "/$match/ && print" $file
}


function mason_append_after()
{
    local env_file=$1
    local tag=$2
    local content=$3
    local before=$tag
    local after="$tag\n$content"
    mason_replace $env_file "$before" "$after"
}

function mason_insert_before()
{
    local env_file=$1
    local tag=$2
    local content=$3
    local before=$tag
    local after="$content\n$tag"
    mason_replace $env_file "$before" "$after"
}


function mason_addpath()
{
    local env_file=$1
    local new_path=$2
    local flag=$3
    case $flag in
        "--front") flag="--front";;
        *) flag="--back";; # default
    esac

    # read out PATH in given environment
    chmod +x $env_file
    local get_cmd="bash -c 'source $env_file;"" echo \$PATH'"
    local curr_path=`eval $get_cmd`

    # check if new_path is already in there
    if echo "$curr_path" | grep -q "$new_path"; then
        echo "'$new_path' already found in PATH!"
        return 1
    fi

    if [ "$flag" = "--back" ]; then
        local content="export PATH=\\\$PATH:$new_path"
        mason_insert_before $env_file "#/PATH" "$content"
    else
        local content="export PATH=$new_path:\\\$PATH"
        mason_insert_before $env_file "#/PATH" "$content"
    fi
}


function mason_addlib()
{
    local env_file=$1
    local lib_path=$2

    # read out LIBRARY_PATH in given environment
    chmod +x $env_file
    local get_cmd="bash -c 'source $env_file;"" echo \$LIBRARY_PATH'"
    local curr_lib_path=`eval $get_cmd`
    # check if lib_path is already in there
    if echo "$curr_lib_path" | grep -q "$lib_path"; then
        echo "'$lib_path' already found in LIBRARY_PATH!"
        return 1
    fi
    # add
    local content="export LIBRARY_PATH=\\\$LIBRARY_PATH:$lib_path"
    mason_insert_before $env_file "#/LIB" "$content"
}

function mason_addsharedlib()
{
    local env_file=$1
    local lib_path=$2

    # read out LD_LIBRARY_PATH in given environment
    chmod +x $env_file
    local get_cmd="bash -c 'source $env_file;"" echo \$LD_LIBRARY_PATH'"
    local curr_lib_path=`eval $get_cmd`
    # check if lib_path is already in there
    if echo "$curr_lib_path" | grep -q "$lib_path"; then
        echo "'$lib_path' already found in LD_LIBRARY_PATH!"
        return 1
    fi
    # add
    local content="export LD_LIBRARY_PATH=\\\$LD_LIBRARY_PATH:$lib_path"
    mason_insert_before $env_file "#/SHAREDLIB" "$content"
}


function mason_addpythonpath()
{
    local env_file=$1
    local lib_path=$2

    # read out LD_LIBRARY_PATH in given environment
    chmod +x $env_file
    local get_cmd="bash -c 'source $env_file;"" echo \$PYTHONPATH'"
    local curr_lib_path=`eval $get_cmd`

    # check if lib_path is already in there
    if echo "$curr_lib_path" | grep -q "$lib_path"; then
        echo "'$lib_path' already found in PYTHONPATH!"
        return 1
    fi
    # add
    local content="export PYTHONPATH=\\\$PYTHONPATH:$lib_path"
    mason_insert_before $env_file "#/PYTHONPATH" "$content"
}


function mason_export()
{
    local env_file=$1
    local export_name=$2
    local export_value=$3

    # read out whether variable is already exported
    local curr_line=$(mason_match_line $env_file "export $export_name=")

    # old way of doing that
    #local get_cmd="bash -c 'source $env_file;"" echo \$$export_name'"
    #local curr_value=`eval $get_cmd`

    if [ "x$curr_line" != "x" ]; then
        # if it's already there, we replace it!
        local before="$curr_line"
        local after="export $export_name=$export_value"
        mason_replace $env_file "$before" "$after"
    else
        local content="export $export_name=$export_value"
        mason_insert_before $env_file "#/EXPORT" "$content"
    fi
}


function mason_modify()
{
    if [ $# -eq 0 ]; then
        mason_modify_usage
        return 1
    fi
    local env_name=$1
    if [ "x$env_name" == "x" ]; then
        mason_modify_usage
    fi
    local ENV_FILE=$ENVIRONMENTS_HOME/$env_name/env.bashrc
    if [ ! -e $ENV_FILE ]; then
        echo "Environment \"$env_name\" not found."
        return 1
    fi
    # modify arguments
    case $2 in
        "addpath")
        shift 2
        mason_addpath $ENV_FILE $@
        ;;
        "addlib")
        shift 2
        mason_addlib $ENV_FILE $@
        ;;
        "addsharedlib")
        shift 2
        mason_addsharedlib $ENV_FILE $@
        ;;
        "addpythonpath")
        shift 2
        mason_addpythonpath $ENV_FILE $@
        ;;
        "export")
        shift 2
        mason_export $ENV_FILE $@
        ;;
        *)
        mason_modify_usage
        ;;
    esac
}


function mason_go()
{
    local env_name=$1
    if [ "x$env_name" == "x" ]; then
        env_name=$CURRENT_ENVIRONMENT
        if [ "x$env_name" == "x" ]; then
            mason_usage
            return 1
        fi
    fi
    local ENV_DIR=$ENVIRONMENTS_HOME/$env_name
    if [ ! -e $ENV_DIR/env.bashrc ]; then
        echo "Environment \"$env_name\" not found."
        return 1
    fi
    cd $ENV_DIR
}


function mason_linux_initialize()
{
    local env_name=$1
    # download and extract Linuxbrew
    mkdir linuxbrew
    wget -qO- https://github.com/Linuxbrew/brew/tarball/master -O master.tar.gz
    tar xf master.tar.gz -C linuxbrew --strip-components=1
    rm -rf master.tar.gz
    # create environment script
    touch env.bashrc
    # and fill with content
cat <<EOF > ./env.bashrc
#UNLOADING_STATE
export MASON_PREV_CURRENT_ENVIRONMENT=\$CURRENT_ENVIRONMENT
export MASON_PREV_PATH=\$PATH
export MASON_PREV_PYTHONPATH=\$PYTHONPATH
export MASON_PREV_MANPATH=\$MANPATH
export MASON_PREV_INFOPATH=\$INFO_PATH
export MASON_PREV_C_INCLUDE_PATH=\$C_INCLUDE_PATH
export MASON_PREV_LIBRARY_PATH=\$LIBRARY_PATH
export MASON_PREV_LD_LIBRARY_PATH=\$LD_LIBRARY_PATH
export MASON_PREV_PS1=\$PS1
#/UNLOADING_STATE

#BASE
ENV_HOME="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"
export CURRENT_ENVIRONMENT=\$(basename \$ENV_HOME)
#/BASE

#PROMPT
PS1=\${PS1/"\$"/"\$CURRENT_ENVIRONMENT \$"}
#/PROMPT

#LINUXBREW
LINUXBREW_HOME="\$ENV_HOME/linuxbrew"
export PATH="\$LINUXBREW_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export MANPATH="\$LINUXBREW_HOME/share/man"
export INFOPATH="\$LINUXBREW_HOME/share/info"
export C_INCLUDE_PATH="\$LINUXBREW_HOME/include"
export LIBRARY_PATH="\$LINUXBREW_HOME/lib"
export LD_LIBRARY_PATH="\$LINUXBREW_HOME/lib"
#/LINUXBREW

#EXPORT
#/EXPORT

#LIB
#/LIB

#SHAREDLIB
#/SHAREDLIB

#PATH
#/PATH

#PYTHONPATH
#/PYTHONPATH

#REHASH
hash -r
#/REHASH

EOF

    # update/initialize homebrew
    ./linuxbrew/bin/brew update
    # deactivate analytics
    ./linuxbrew/bin/brew analytics off
}


function mason_darwin_initialize()
{
    local env_name=$1
    # download and extract homebrew
    mkdir homebrew
    wget -qO- https://github.com/Homebrew/brew/tarball/master -O master.tar.gz
    tar xf master.tar.gz -C homebrew --strip-components=1
    rm -rf master.tar.gz
    # create environment script
    touch env.bashrc
    # and fill with content
cat <<EOF > ./env.bashrc
#UNLOADING_STATE
export MASON_PREV_CURRENT_ENVIRONMENT=\$CURRENT_ENVIRONMENT
export MASON_PREV_PATH=\$PATH
export MASON_PREV_PYTHONPATH=\$PYTHONPATH
export MASON_PREV_MANPATH=\$MANPATH
export MASON_PREV_INFOPATH=\$INFO_PATH
export MASON_PREV_C_INCLUDE_PATH=\$C_INCLUDE_PATH
export MASON_PREV_LIBRARY_PATH=\$LIBRARY_PATH
export MASON_PREV_LD_LIBRARY_PATH=\$LD_LIBRARY_PATH
export MASON_PREV_PS1=\$PS1
#/UNLOADING_STATE

#BASE
ENV_HOME="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"
export CURRENT_ENVIRONMENT=\$(basename \$ENV_HOME)
#/BASE

#PROMPT
PS1=\${PS1/"\$"/"\$CURRENT_ENVIRONMENT \$"}
#/PROMPT

#HOMEBREW
HOMEBREW_HOME="\$ENV_HOME/homebrew"
export PATH="\$HOMEBREW_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export C_INCLUDE_PATH="\$HOMEBREW_HOME/include"
export LIBRARY_PATH="\$HOMEBREW_HOME/lib"
export LD_LIBRARY_PATH="\$HOMEBREW_HOME/lib"
#/HOMEBREW

#EXPORT
#/EXPORT

#LIB
#/LIB

#SHAREDLIB
#/SHAREDLIB

#PATH
#/PATH

#PYTHONPATH
#/PYTHONPATH

#REHASH
hash -r
#/REHASH

EOF

    # update/initialize homebrew
    ./homebrew/bin/brew update
    # deactivate analytics
    ./homebrew/bin/brew analytics off
    # install gnu sed for osx
    ./homebrew/bin/brew install gnu-sed --with-default-names

}

function mason_welcome()
{
    local env_name=$1
    local env_dir=$ENVIRONMENTS_HOME/$env_name
    echo
    echo "Load Environment"
    echo "       Mason:    mason load $env_name"
    echo "      Source:    source $env_dir/env.bashrc"
    echo
    echo "Environment Package Managers"
    echo "    Software:    brew search/list/install"
    echo "    Anaconda:    conda search/list/install/update"
    echo "      Python:    pip search/install/list"
    echo
    echo "You are good to go."
    echo
}

function mason_create()
{
    # environment name and directory
    local env_name=$1
    local env_dir="$ENVIRONMENTS_HOME/$env_name"
    # check for empty arguments
    if [ "x$env_name" == "x" ]; then
        mason_usage
        return 1
    fi
    # check for empty arguments
    if [ -d "$env_dir" ]; then
        "Environment '$env_dir' already exists! Remove it for recreation"
        return 1
    fi
    # remember folder
    local cwd=$(pwd)
    # initialize
    local platform=$(uname)
    if [[ "$platform" == 'Darwin' ]]; then
        mkdir -p $env_dir # create folder
        cd "$env_dir"
        mason_darwin_initialize $env_name
        cd "$cwd"
    elif [[ "$platform" == 'Linux' ]]; then
        mkdir -p $env_dir # create folder
        cd "$env_dir"
        mason_linux_initialize $env_name
        cd "$cwd"
    else
        echo 'Platform $platform not supported!'
        return 1
    fi
    # echo feedback
    echo
    echo "Created environment '$env_name'."
}


function mason_usage()
{
    cat <<EOF
USAGE:
  mason                                     --show this help
  mason create ENVIRONMENT                  --create new environment
  mason edit [ENVIRONMENT]                  --open (current) configuration script
  mason go [ENVIRONMENT]                    --cd to (current) environment home
  mason install [ENVIRONMENT] GRAVEL        --install Mason package
  mason list                                --list all environments
  mason load ENVIRONMENT                    --load environment by name
  mason modify ENVIRONMENT                  --modify environment
  mason remove ENVIRONMENT                  --remove existing environment
  mason switch                              --switch environment by choice
  mason toggle                              --toggle current environment
EOF
}


function mason()
{
    # check whether we are good to go
    if [ "x$ENVIRONMENTS_HOME" == "x" ]; then
        echo "For mason to work you need to set ENVIRONMENTS_HOME"
        return 1
    fi

    # get command and shift args to the left
    local cmd=$1
    shift

    # check arguments
    case $cmd in
        "create")
            mason_create $@
            ;;
        "edit")
            mason_edit $@
            ;;
        "go")
            mason_go $@
            ;;
        "install")
            mason_install $@
            ;;
        "list")
            mason_list
            ;;
        "load")
            mason_load $@
            ;;
        "modify")
            mason_modify $@
            ;;
        "remove")
            mason_remove $@
            ;;
        "switch")
            mason_switch
            ;;
        "toggle")
            mason_toggle
            ;;
        *) # unknown
            mason_usage
            ;;
    esac
}