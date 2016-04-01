# Disable support for auto-identifiers and explicitly allow header attributes.
# We don't generate identifiers from headers because we want the identifiers
# to be stable to allow references from other documents, but we want to allow
# the header text to be changed.  Plus the auto-identifiers end up too verbose.
MD_DIALECT := markdown+definition_lists+header_attributes-auto_identifiers

# We also want definitions and YAML metadata blocks.
MD_DIALECT := $(MD_DIALECT)+definition_lists+yaml_metadata_block

%.html:	%.md
	pandoc -f $(MD_DIALECT) -o "$@" "$^"

PDF_OPTS=-V documentclass:article --chapters -V papersize:a4 \
         -V fontsize:11pt -V fontfamily:fhiso -V geometry:a4paper \
         --latex-engine=xelatex

%.pdf: %.md fhiso.sty logo.png pandoc.mk
	pandoc $(PDF_OPTS) -f $(MD_DIALECT) -o "$@" "$<"

.dialect:
	@echo -n "$(MD_DIALECT)" > $@

