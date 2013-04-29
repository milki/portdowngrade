#!/usr/local/bin/bash

SVN=/usr/local/bin/svn
GIT=/usr/local/bin/git
GITSVN="$GIT svn"
BASH=/usr/local/bin/bash
TAR=/usr/bin/tar
RM=/bin/rm
SUDO=/usr/local/bin/sudo

: ${PORTSDIR:="/usr/ports"}

commits=()
version_menu=()

function usage {
    echo "usage: portdowngrade.sh <origin/portname>"
}

function verify_portname {
    port=$1
    if [ "$port" == "" ]
    then
        usage
        exit 1
    fi
    [ -d $PORTSDIR/$port ] || (echo "$port does not exist in $PORTSDIR" && exit 1)
}

function clone_repo {
    port=$1
    echo "Finding revisions for $port"
    rev=$($SVN log "https://svn0.us-west.FreeBSD.org/ports/head/$port"  | grep -E "^r[[:digit:]]+[[:space:]].*lines$" | awk 'BEGIN { FS = " "} { print $1 }' | tail -n 1)
    $GITSVN clone -r ${rev:1}:HEAD -q https://svn0.us-west.FreeBSD.org/ports/head/$port .
}

function retrieve_history {
    # Match version to commit
    for commit in $(git log --pretty=%H Makefile)
    do
        $GIT checkout $commit Makefile

        pkgversion=$(make -V PKGVERSION)
        #history[$pkgversion]=$commit

        log=$(git log --pretty=%s $commit -n 1)

        commits+=("$commit")
        version_menu+=( "$(printf '%-20s %-s\n' $pkgversion "$log")" )
    done
}

function choose_version {
    echo "Choose a port version: "
    select version in "${version_menu[@]}"; do
        if [ "$version" == "$QUIT" ]
        then
            echo "Quitting..."
            cleanup
            exit 0
        fi

        PS3="Your choice: "
        choice=$REPLY
        case $choice in
            *)
                let "choice -= 1"
                $GIT log ${commits[$choice]} -n 1

                read -p "Choose this port version (y/n)? "
                case $REPLY in
                    y|Y|yes|Yes|YES)
                        $GIT reset --hard ${commits[$choice]}

                        echo "Verify the port dir. Exit the shell when done."
                        $BASH

                        read -p "Continue with this version? (y/n) "
                        case $REPLY in
                            y|Y|yes|Yes|YES)
                                echo "Continuing..."
                                return
                                ;;
                        esac
                        ;;
                esac
                ;;
        esac
    done
}

function export_to_portstree {
    # sudo
    $GIT archive --format=tar HEAD | (cd $PORTSDIR/$portname/ && $SUDO $TAR -xf -)
}

function cleanup {
    cd - > /dev/null
    $RM -rf $TMPDIR
}

portname=$1
verify_portname $portname

TMPDIR=$(mktemp -d -t portdowngrade)
cd $TMPDIR

clone_repo $portname
retrieve_history
choose_version
export_to_portstree
cleanup
