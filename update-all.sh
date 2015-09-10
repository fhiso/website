#!/bin/sh

set -e 

rm -rf $HOME/www-build

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
cd cfps_processor; python makeindex.py > index.html; cd ..
perl build-site.pl

mkdir -p $HOME/www-build/cfps/files
rsync -r cfps_processor/ready/ $HOME/www-build/cfps/files/

rsync -r $HOME/www-build/ $HOME/www/

