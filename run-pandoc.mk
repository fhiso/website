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

# Disable support for auto-identifiers and explicitly allow header attributes.
# We don't generate identifiers from headers because we want the identifiers
# to be stable to allow references from other documents, but we want to allow
# the header text to be changed.  Plus the auto-identifiers end up too verbose.
MD_DIALECT := markdown+definition_lists+header_attributes-auto_identifiers

# We also want definitions and YAML metadata blocks.
MD_DIALECT := $(MD_DIALECT)+definition_lists+yaml_metadata_block
MD_DIALECT := $(MD_DIALECT)+shortcut_reference_links
MD_DIALECT := $(MD_DIALECT)+simple_tables+multiline_tables

PANDOC := pandoc

# Allow any changes for the local machine.
# (E.g. to set PANDOC=schroot -c testing -- pandoc.)
-include local-settings.mk
-include $(ROOT)/website/local-settings.mk


# This is our own markdown preprocessor
PPMD := $(ROOT)/website/preprocess-md.pl


%.html:	%.md $(ROOT)/website/run-pandoc.mk
	$(PPMD) < "$<" | $(PANDOC) -f $(MD_DIALECT) -o "$@"

# Setting fontfamily=fhiso is a bit of an abuse, as fhiso.sty does much 
# more than just setting the font.
PDF_OPTS := -V documentclass:article --chapters -V papersize:a4paper -V dir:1 \
            -V fontsize:11pt -V fontfamily:$(ROOT)/website/fhiso \
	    -V header-includes:\\fhisoFinal --latex-engine=xelatex --standalone

PDF_DEPS := $(ROOT)/website/fhiso.sty $(ROOT)/website/logo.png

%.pdf: %.md $(PDF_DEPS) $(ROOT)/website/run-pandoc.mk
	$(PPMD) < "$<" | $(PANDOC) $(PDF_OPTS) -f $(MD_DIALECT) -o "$@"

%.tex: %.md $(PDF_DEPS) $(ROOT)/website/run-pandoc.mk
	$(PPMD) < "$<" | $(PANDOC) $(PDF_OPTS) -f $(MD_DIALECT) -o "$@" 

