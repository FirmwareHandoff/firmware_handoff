.. SPDX-License-Identifier: CC-BY-SA-4.0
.. SPDX-FileCopyrightText: Copyright The Firmware Handoff Specification Contributors

.. _handoff_arch_bindings:

Register usage at handoff boundary
==================================

This section specifies the architecture bindings for the TL exchange at the
handoff boundary.

Arm Architecture bindings
-------------------------

The Receiver of a TL can be in the AArch32 or AArch64 execution state [ArmARM]_.
The register convention to be used at the handoff boundary is determined by the
execution state of the Receiver.
If the Receiver is in the AArch64 execution state, then the convention listed
in :numref:`aarch64_receiver` is used.  If the Receiver is in the AArch32 execution state,
then the convention listed in :numref:`aarch32_receiver` is used.


.. _aarch64_receiver:

AArch64 Receiver
^^^^^^^^^^^^^^^^

A Sender must use the register convention listed in Table 3 when handing off to an AArch64 receiver.
In this register convention, the pointer to the 64-bit tl_base_pa address is passed on register X3.

Register X2 must be set to 0.

The 32 least significant bits in register X1 contains the TL signature. The
*signature* provides guarantees to a receiver that X3 holds the *tl_base_pa*. The
bits [39:32] of X1 contain the version of the register convention being used.
:numref:`tab_aarch64_convention` specifies the version 1 of the AArch64 handoff register convention.

Register X0 must hold a pointer to the hardware description devicetree, if the
transfer list contains an FDT entry. This field is set to 0 if an fdt entry is
absent from the transfer list.


.. _tab_aarch64_convention:

.. table:: AArch64 register assignment at the handoff boundary
   :widths: 2 8

   +--------------+-------------------------------------------------------------+
   | Register     | Data present at the handoff boundary                        |
   +--------------+-------------------------------------------------------------+
   | X0           | Compatibility location for passing a platform description   |
   |              | devicetree. 0 if devicetree is not present. If an fdt entry |
   |              | (tag_id=1) exists in the TL, then X0 must point to the fdt  |
   |              | contained in that entry.                                    |
   +--------------+-------------------------------------------------------------+
   | X1           | X1 is divided into the following fields:                    |
   |              |                                                             |
   |              | - X1[31:0]: set to the TL signature (4a0f_b10b)             |
   |              | - X1[39:32]: version of the register convention used. Set to|
   |              |   1 for the AArch64 convention specified in this document.  |
   |              | - X1[63:40]: reserved, must be zero.                        |
   |              |                                                             |
   +--------------+-------------------------------------------------------------+
   | X2           | Reserved, must be zero.                                     |
   +--------------+-------------------------------------------------------------+
   | X3           | tl_base_pa                                                  |
   +--------------+-------------------------------------------------------------+


.. _aarch32_receiver:

AArch32 Receiver
^^^^^^^^^^^^^^^^

A Sender must use the register convention listed in
:numref:`tab_aarch32_convention` when handing off to an AArch32 receiver. In
this register convention, the pointer to the 32-bit
tl_base_pa address is passed on register R3.
Register R1 contains the TL signature, to provide guarantees to a receiver that
R3 holds the tl_base_pa.

The 24 least significant bits in register R1 contains the 24 least significant
bits of TL signature. The signature provides guarantees to a receiver that X3
holds the tl_base_pa. The 8 most significant bits of R1 contain the version of
the register convention being used. Table 4 specifies the version 1 of the AArch32
handoff register convention.

Register R2 must hold a pointer to the hardware description devicetree, if the
transfer list contains an FDT entry. This field is set to 0 if an fdt entry is
absent from the transfer list.

.. _tab_aarch32_convention:

.. table:: AArch32 register assignment at the handoff boundary
   :widths: 2 8

   +--------------+-------------------------------------------------------------+
   | Register     | Data present at the handoff boundary                        |
   +--------------+-------------------------------------------------------------+
   | R0           | Reserved, must be zero.                                     |
   +--------------+-------------------------------------------------------------+
   | R1           | R1 is divided into the following fields:                    |
   |              |                                                             |
   |              | - R1[23:0]: set to the 24 least significant bits of TL      |
   |              |   signature (0f_b10b).                                      |
   |              | - R1[31:24]: version of the register convention used. Set to|
   |              |   1 for the AArch32 convention specified in this document.  |
   |              |                                                             |
   +--------------+-------------------------------------------------------------+
   | R2           | Compatibility location for passing a platform description   |
   |              | devicetree. 0 if devicetree is not present. If an fdt entry |
   |              | (tag_id=1) exists in the TL, then R2 must point to the fdt  |
   |              | contained in that entry.                                    |
   +--------------+-------------------------------------------------------------+
   | R3           | tl_base_pa                                                  |
   +--------------+-------------------------------------------------------------+
