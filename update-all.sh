#!/bin/sh

set -e 

OUT=$HOME/www
BUILD=$HOME/www-build

rm -rf $BUILD

cd $HOME/lexicon-eg
git pull -q
cd builder
python mergemd.py
ln -sf lexicon-$(TZ=UTC date +%Y-%m-%d).md snapshot.md

cd $HOME/tsc-governance
git pull -q

cd $HOME/sources-and-citations-eg
git pull -q

cd $HOME/bibliography
git pull -q

cd $HOME/website
git pull -q
perl build-site.pl
rsync -rp include/ $BUILD/include/

mkdir -p $BUILD/cfps/files
rsync -rp cfps_processor/ready/ $BUILD/cfps/files/

# At the moment the database is built from the JSON file in git.
# This is a temporary arrangement while the old and new sites are 
# running in parallel.  This will trash and recreate the database.
./mysql.php < cfps_processor/schema.sql
./cfps_processor/import.php

rsync -rp $BUILD/ $OUT/

