# This Makefile is here for convenience as a wrapper around pandoc.mk.  
# To use it simply define SOURCES and (if necessary) ROOT and REPO, and 
# include this file, e.g.
#   SOURCES := foo.md bar.md
#   include ../website/run-pandoc.mk

# $(SOURCES) is the list of markdown sources.
SOURCES ?= 

# $(ROOT) is the path to the directory containing checkouts of the various
# github repositories.
ROOT    ?= ..

# $(REPO) is the path to the current directory from $(REPO)
REPO    ?= $(shell basename `pwd`)



all:	pdf
pdf:	$(SOURCES:%.md=%.pdf)
html:	$(SOURCES:%.md=%.html)

clean:
	rm -f $(SOURCES:%.md=%.pdf) $(SOURCES:%.md=%.html)

.PHONY: all pdf html clean

%.pdf: %.md
	$(MAKE) -C $(ROOT)/website -f pandoc.mk "$(ROOT)/$(REPO)/$@"

%.html: %.md
	$(MAKE) -C $(ROOT)/website -f pandoc.mk "$(ROOT)/$(REPO)/$@"

