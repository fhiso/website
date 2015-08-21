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
perl build-site.pl

rsync -r $HOME/www-build/ $HOME/www/

