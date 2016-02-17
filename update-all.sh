#!/bin/sh

set -e

ROOT=$HOME

# To override the directory the site is built in, create a file called
# local-settings in this directory.
if [ -e $(dirname $0)/local-settings ] ; then
    . $(dirname $0)/local-settings
fi

# Note that www-build is the document root for http://test.tech.fhiso.org/
BUILD=$ROOT/www-build
OUT=$ROOT/www

# Git repositories we use
REPOS="lexicon-eg tsc-governance sources-and-citations-eg bibliography website"

if [ $# -eq 1 -a "$1" = '--help' ]; then
    cat <<EOF 
Usage: $(basename $0) [OPTION]

  --help      Display this message and exit
  --testing   Do not pull from git or deploy to the live server
  --deploy    Force the deployment of a dirty checkout to the live server

EOF
    exit;
fi

DIRTY=""
if [ $# -ne 1 -o "$1" != '--testing' ]; then
    for REPO in $REPOS; do
        cd $ROOT/$REPO
        git pull -q
        if git status --porcelain | grep -q . ; then
            DIRTY="$DIRTY $REPO"
        fi
    done
fi

cd $ROOT/lexicon-eg/builder
rm -f lexicon-*.md
python mergemd.py
ln -sf lexicon-$(TZ=UTC date +%Y-%m-%d).md snapshot.md

rm -rf $BUILD
mkdir -p $BUILD
cd $ROOT/website
perl build-site.pl
rsync -rp include/ $BUILD/include/
rsync -rp account/ $BUILD/account/

mkdir -p $BUILD/cfps/files
rsync -rp cfps_processor/ready/ $BUILD/cfps/files/

# At the moment the database is built from the JSON file in git.
# This is a temporary arrangement while the old and new sites are 
# running in parallel.  This will trash and recreate the database.
./mysql.php < cfps_processor/schema.sql
./cfps_processor/import.php

if [ $# -eq 1 -a "$1" = '--testing' ]; then
    :
elif [ -z "$DIRTY" -o $# -eq 1 -a "$1" = '--deploy' ]; then
    # The code above will dump data in $BUILD and never touch the www root.
    # This is the only place where the main www root is populated.
    rsync -rp $BUILD/ $OUT/
else
    cat <<EOF >&2
Not deploying a checkout with local modifications in these repositories:
 $DIRTY
Re-run with --deploy to force a deployment.
EOF
fi
