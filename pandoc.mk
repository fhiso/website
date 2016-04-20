# Disable support for auto-identifiers and explicitly allow header attributes.
# We don't generate identifiers from headers because we want the identifiers
# to be stable to allow references from other documents, but we want to allow
# the header text to be changed.  Plus the auto-identifiers end up too verbose.
MD_DIALECT := markdown+definition_lists+header_attributes-auto_identifiers

# We also want definitions and YAML metadata blocks.
MD_DIALECT := $(MD_DIALECT)+definition_lists+yaml_metadata_block
MD_DIALECT := $(MD_DIALECT)+shortcut_reference_links

PANDOC := pandoc

# Allow any changes for the local machine.
# (E.g. to set PANDOC=schroot -c testing -- pandoc.)
-include local-settings.mk

%.html:	%.md
	./pclasses.pl < "$<" | $(PANDOC) -f $(MD_DIALECT) -o "$@"

# Setting fontfamily=fhiso is a bit of an abuse, as fhiso.sty does much 
# more than just setting the font.
PDF_OPTS=-V documentclass:article --chapters -V papersize:a4paper -V dir:1 \
         -V fontsize:11pt -V fontfamily:fhiso -V header-includes:\\fhisoFinal \
         --latex-engine=xelatex --standalone

%.pdf: %.md fhiso.sty logo.png pandoc.mk
	./pclasses.pl < "$<" | $(PANDOC) $(PDF_OPTS) -f $(MD_DIALECT) -o "$@"

%.tex: %.md fhiso.sty logo.png pandoc.mk
	./pclasses.pl < "$<" | $(PANDOC) $(PDF_OPTS) -f $(MD_DIALECT) -o "$@" 
