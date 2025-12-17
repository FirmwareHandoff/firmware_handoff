[![Build Status](https://github.com/FirmwareHandoff/firmware_handoff/actions/workflows/main.yml/badge.svg)](https://github.com/FirmwareHandoff/firmware_handoff/actions/workflows/main.yml)
[![Daily Status](https://github.com/FirmwareHandoff/firmware_handoff/actions/workflows/daily.yml/badge.svg)](https://github.com/FirmwareHandoff/firmware_handoff/actions/workflows/daily.yml)
[![Release Version](https://img.shields.io/github/v/release/FirmwareHandoff/firmware_handoff?label=release)](https://github.com/FirmwareHandoff/firmware_handoff/releases)

This repository contains the Firmware Handoff specification, which defines a
data structure to transfer essential configuration information between firmware
stages during platform initialization.

Note that versions 0.9 and 1.0 of this specification are withdrawn and should not be used for product development.

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

Reference implementation
========================

The specification has a library reference implementation, its hosted upstream in the following
repository: [Transfer List Library](https://github.com/TF-Shared/transfer-list-library).

The library can be leveraged by different firmware projects. It implements all the relevant
operations on the Transfer List.

The U-Boot project hosts another library implementation, referred to as Bloblist, which it can be found at
[Bloblist Source](https://github.com/u-boot/u-boot/blob/master/common/bloblist.c).


Status
======

As of November 2025, version 1.0 is withdrawn and should not be used.
Version 1.0 was withdrawn because products shipped with a TL header cheksum implementation that differed from the version 1.0 definition.

Version 2.0 of the specification is the latest release.
Implementations should adopt version 2.0 of the specification.
