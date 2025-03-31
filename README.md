[![Build Status](https://github.com/FirmwareHandoff/firmware_handoff/actions/workflows/main.yml/badge.svg)](https://github.com/FirmwareHandoff/firmware_handoff/actions/workflows/main.yml)
[![Daily Status](https://github.com/FirmwareHandoff/firmware_handoff/actions/workflows/daily.yml/badge.svg)](https://github.com/FirmwareHandoff/firmware_handoff/actions/workflows/daily.yml)
[![Release Version](https://img.shields.io/github/v/release/FirmwareHandoff/firmware_handoff?label=release)](https://github.com/FirmwareHandoff/firmware_handoff/releases)

This repository contains the Firmware Handoff specification, which defines a
data structure to transfer essential configuration information between firmware
stages during platform initialization.

The documentation is generated using the Sphinx framework. A version of this
specification, rendered in HTML, is available
[here](https://firmwarehandoff.github.io/firmware_handoff/).

Project dependencies
====================

For an Ubuntu development machine, install the following packages to build the specification:

- `librsvg2-bin`
- `python3-sphinx`
- `python3-sphinxcontrib.svg2pdfconverter`
- `python3-sphinx-rtd-theme`
- `sphinx-multiversion`
- `latexmk`
- `texlive-latex-extra`

**Note:** This list has been tested on Ubuntu 22.04 LTS and 24.04 LTS running on AArch64 and AMD64.

Building the document
=====================

The following are use to generate the specification:

- pdf:

``` sh
make latexpdf
```

- html:

``` sh
make html
```

The output of these build commands goes into subdirectory `build`.

Status
======

The first release of the specification has been published. We are currently in
the implementation phase, looking at various target projects, including U-Boot,
coreboot, TF-A and Tianocore. Once this is done we will review the result to see
if any serious flaws have come to light, meaning that changes are needed.  If
so, these will be undertaken in each project.

By the end of 2024, the spec will be considered stable and will be published
as version 1. From there on, backwards compatibility will be maintained.
