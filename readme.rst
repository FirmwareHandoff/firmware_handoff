This repository contains the Firmware Handoff specification.

This specification is generated using the sphinx framework.

Project dependencies
====================

For a ubuntu development machine, the following packages must be installed to
enable building the specification:

- librsvg2-bin
- python3-sphinx
- python3-sphinxcontrib.svg2pdfconverter
- latexmk
- texlive-latex-extra

Note: the list above was tested on Ubuntu 20.04 LTS and 22.04 LTS running on
AArch64 and Amd64.

Building the document
=====================

The following are use to generate the specification:

 - pdf:
    make latexpdf

 - html:
    make html

Status
======

As of February 2023 the spec is in the process of being finalised. Once this is
complete and everyone is in agreement with the content, we will issue a 0.9
release. We will then look to implement it in various target projects, including
U-Boot, coreboot, TF-A and Tiancore. Once this is done we will review the result
to see if any serious flaws have come to light, meaning that changes are needed.
If so, these will be undertaken in each project.

By the end of 2023, the spec will be considered stable and will be published
as version 1. From there on, backwards compatibility will be maintained.
