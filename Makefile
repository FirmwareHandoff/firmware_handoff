# Minimal makefile for Sphinx documentation
#

IMG_DIR = source/images
IMG_SRC = $(wildcard $(IMG_DIR)/*.svg)
IMG_TGT = $(patsubst %.svg,%.pdf,$(IMG_SRC))

# You can set these variables from the command line.
SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
SOURCEDIR     = source
BUILDDIR      = build

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile images

images: $(IMG_TGT)

%svg:;

%.pdf: %.svg
	@rsvg-convert -f pdf -o $@ $<

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile images
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
