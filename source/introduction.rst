.. SPDX-License-Identifier: CC-BY-SA-4.0
.. SPDX-FileCopyrightText: Copyright The Firmware Handoff Specification Contributors

Introduction
============

A platform initialization procedure may involve the execution of a sequence of
firmware stages. It is assumed that only the primary boot core is active during
the transition point between firmware stages, the remaining cores must be held
at reset. The distinct firmware stages have specific responsibilities
and can originate from separate codebases. As a platform initializes, the
different firmware stages will generate information about the platform
configuration and architecture.
Examples of the information generated during boot are the platform memory map and
device configuration.
This information can be required by later
firmware stages and thus must be propagated along the boot chain.  This
document defines a data structure which is used to handoff information between
the different firmware stages involved in the platform initialization.


Platform initialisation stages
------------------------------

An example of a feasible platform-boot architecture is shown in
:numref:`fig_boot_phases`. This example is provided to introduce the firmware
stage concept. Platforms are free to adopt any other boot architecture.

.. _fig_boot_phases:
.. figure:: images/boot_phases.svg
   :alt: Example boot architecture

   Example boot architecture


Depending on the platform, the cold-boot initialization can start from a Board
Controller which then releases the Application Processor (AP) into execution.

The boot process on the AP can conceptually be broken apart into the following
stages:

* Immutable

  * Firmware stage obtained from read only memory. The immutable stage loads and authenticates the next stage into RAM and may perform some AP initialization.

* Secure Platform Firmware

  * Firmware stage that is executed in a privileged level. It is responsible for loading additional firmware images and optionally performing platform configurations. The stage can be subdivided into other sub-stages. The stage terminates with the transition to the OS Bootloader.

* OS Bootloader

  * The firmware stage that executes before the OS. It is responsible for configuring the platform, loading and transferring the execution to the OS. This stage can be composed of several sub-stages.


Any stage in the AP boot procedure can produce information which is consumed by
a later stage.
This specification defines the concept of *Transfer List* (TL --
:numref:`sec_tl`). A firmware stage can append information to the TL.
Any information produced by a firmware stage, meant to be
consumed by a later firmware stage, must be contained in an entry
(:numref:`sec_tl`) in the TL or be directly accessible via the information
contained in one of the entries in the TL.
A firmware stage transfers the execution flow to a next firmware stage at a point termed the
*handoff boundary*. The TL is transferred between stages at the *handoff boundary*.
For a particular *handoff boundary*, the firmware stage that hands
off the list to a next stage is termed the *Sender*. The firmware stage
receiving the list is termed the *Receiver*. The *Receiver* can update fields in
any entry in the list and is allowed to remove entries.


.. note::

   If a firmware phase fails, the execution flow on the previous stage
   should resume from the handoff point. It is recommended that a previous
   phase keeps information on the execution flow prior to handoff either
   explicitly or implicitly in a link register.
