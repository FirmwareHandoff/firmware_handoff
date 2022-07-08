This repository contains the Firmware Handoff specification.

This specification is generated using the sphinx framework.

Project dependencies
====================

For a ubuntu development machine, the following packages must be installed to
enable building the specification:

- librsvg2-bin
- python3-sphinx
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
