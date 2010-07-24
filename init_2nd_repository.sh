#!/bin/sh

if [ "$1" = "-h" ] || [ "$1" = "--help" ];then
echo Configure a clone repository in order to manage two separate disjoint
echo Git repositories in this same current folder: that is no files should be
echo tracked by both of them.
exit 0
fi

if [ -e ".msg.git" ];then
	echo 2>&1 ".msg.git alread exist, aborting !"
	exit -1
fi
 
# The first directory will continue to use `git` and store is
# information in ".git", but it's ".gitignore" file shall be freeze,
# copy to ".git/info/exclude" and remove from the view of the second
# repository
if [ -e ".gitignore" ];then
	cat .gitignore >>.git/info/exclude
	git update-index --assume-unchanged .gitignore
	rm .gitignore
fi

# The second repository will have a separated $GIT_DIR (let's say
# ".msg.git") and will also manage its own list of excluded files in
# ".msg.git/info/exclde"
WORKING_DIR=`pwd`
GIT_DIR=".msg.git"
alias msg="git --git-dir=$WORKING_DIR/$GIT_DIR --work-tree=$WORKING_DIR"

msg init

echo For convenience, you can add the following lines in your ~/.profile:
echo	alias `alias msg`
echo

echo >>$GIT_DIR/info/exclude "# Ignore our current \$GIT_DIR"
echo >>$GIT_DIR/info/exclude "$GIT_DIR"
echo >>$GIT_DIR/info/exclude "# Ignore files already managed in \".git\""
echo >>$GIT_DIR/info/exclude "`ls`"

echo """
You can now manage your private stuff with the previous \"msg\" alias.
Just be sure to add --force your private configuration file with \"msg\"
and not \"git\":
	bash $ vim Scripts/XML-RPC/private.cfg
	bash $ msg add -f Scripts/XML-RPC/private.cfg
	bash $ make new
	New directory created: [999_foobar]
	bash $ msg add -f 999_foobar

Change to Scripts/ or Template/ will be managed by git:
	bash $ echo \"# FOOBAR\" >>README
	bash $ git status
	bash $ msg status
"""
