#!/bin/bash

#
# To use this checker script, add the following lines to your $HOME/.hgrc file,
# and ensure this script is in your path.
#
#    [hooks]
#    pre-commit.subrepo = hg_subrepo_commit_check.sh
#

RED='\033[1;31m'
MAGENTA='\033[1;35m'
NORMAL='\033[0m'

# If the environment variable "SUBREPO" is set, allow changes.
[ -n "$SUBREPO" ] && exit 0

root=`hg root` || exit 1

# Exit if there are no subrepos.
[ -e "$root/.hgsub" ] || exit 0

prompt_user=0

# Display changes in this repository.
changes=`hg status -mar --color always` || exit 1
if [ -n "$changes" ] ; then
    echo -e "The ${RED}top-level${NORMAL} repository has outstanding changes:"
    echo "$changes"
    prompt_user=1
fi

# If there is no .hgsubstate, there's not much we can do.
if ! [ -e "$root/.hgsubstate" ] ; then
    cat <<EOT
Warning: .hgsub exists, but there is no .hgsubstate.
The pre-commit hook cannot perform any validity checks - you are on your own.
EOT
    echo -n "Do you wish to commit anyway (yes/no)? "
    read || exit 1
    [ "$REPLY" = "yes" ] && exit 0
    [ "$REPLY" = "no" ] || echo "I'll take that as a no. Aborting."
    exit 1
fi

while read substaterev subdir ; do
    if ! [ -d "$root/$subdir" ] ; then
        echo -e "Subrepo $RED$subdir$NORMAL does not exist. Cannot do sanity checks on it!"
        prompt_user=1
        continue
    fi

    cd $root/$subdir || exit 1

    if [ -d ".hg" ] ; then
        # See if there are any outstanding modifications in this repo.
        changes=`hg status -mar --color always` || exit 1
        if [ -n "$changes" ] ; then
            prompt_user=1
            echo -e "$RED$subdir$NORMAL has outstanding changes:"
            echo "$changes"
        fi
    elif [ -d ".git" ] ; then
        # This is a git repo.
        WHICH_GIT=`which git 2>/dev/null`
        if [ ! -n "${WHICH_GIT}" ]; then
            prompt_user=1
            echo -e "${RED}${subdir}${NORMAL} is a git repo, but it looks like you don't have git installed. I can't tell you anything about this repo."
        else
            changes=`git status -s` || exit 1
            if [ -n "$changes" ] ; then
                prompt_user=1
                echo -e "${RED}${subdir}${NORMAL} has outstanding changes:"
                echo "${changes}"
            fi
        fi
    else
        echo -e "Subrepo $RED$subdir$NORMAL is not a hg repository."
        echo "I don't know how to examine this."
        prompt_user=1
        continue
    fi
done < $root/.hgsubstate

while read substaterev subdir ; do
    if ! [ -d "$root/$subdir" ] ; then
        # We alerted the user earlier.
        continue
    fi

    cd $root/$subdir || exit 1

    if [ -d ".hg" ] ; then
        # Determine if versions of subrepos have changed since the last commit.
        currev=`hg parent --template '{node}'` || exit 1
        if [ $substaterev != $currev ] ; then
            prompt_user=1
            substateid=`hg log -r $substaterev --template '{rev}'`
            curid=`hg log -r $currev --template '{rev}'`
            echo -e "$RED$subdir$NORMAL is at a different revision (was $MAGENTA$substateid$NORMAL, now $MAGENTA$curid$NORMAL)."
        fi
    fi
done < $root/.hgsubstate

if [ "$prompt_user" = 1 ] ; then
    echo
    echo "    Note: the above information may not be relevant if you"
    echo "          are committing specific files/directories."
    echo -n "Do you wish to commit anyway (yes/no)? "
    read || exit 1
    [ "$REPLY" = "yes" ] && exit 0
    [ "$REPLY" = "no" ] || echo "I'll take that as a no. Aborting."
fi

exit $prompt_user

