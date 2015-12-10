#!/bin/sh

set -e

ROOT=$HOME

# To override the directory the site is built in, create a file called
# local-settings in this directory.
if [ -e $(dirname $0)/local-settings ]; then
    . $(dirname $0)/local-settings
fi

OUT=$ROOT/www
BUILD=$ROOT/www-build

rm -rf $BUILD

cd $ROOT/lexicon-eg
git pull -q
cd builder
python mergemd.py
ln -sf lexicon-$(TZ=UTC date +%Y-%m-%d).md snapshot.md

cd $ROOT/tsc-governance
git pull -q

cd $ROOT/sources-and-citations-eg
git pull -q

cd $ROOT/bibliography
git pull -q

cd $ROOT/website
git pull -q
mkdir -p $BUILD
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

rsync -rp $BUILD/ $OUT/

