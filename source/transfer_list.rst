.. SPDX-License-Identifier: CC-BY-SA-4.0
.. SPDX-FileCopyrightText: Copyright The Firmware Handoff Specification Contributors

.. _sec_tl:

Transfer list
=============

The TL is composed of a TL header which is followed by sequence of Transfer
Entries (TE). The whole TL is PA-contiguous, the TL header and all the TEs are
16-byte aligned. The TL header specifies the number of bytes occupied by the
TL. The TEs are defined in :numref:`sec_tl_entry_hdr` and
:numref:`sec_std_entries`. Each TE carries a header which contains an
identifier, *tag_id*, that is used to determine the content of the associated
TE. The TL header is located at *tl_base_pa*. The *tl_base_pa* is passed in the
register allocated for that handoff boundary (as specified in
:numref:`handoff_arch_bindings`). A
depiction of the TL is present in :numref:`fig_list` , there the first TE in
the list (TE[0]) is shown to start at the end of the TL header (tl_base_pa +
32). The second TE in the list (TE[1]) starts at the next multiple of 16, after
the end of the TE[0].


.. _fig_list:
.. figure:: images/handoff_list_diagram.pdf
   :alt: Transfer list example
   :scale: 85%

   Transfer list example

Transfer list requirements
--------------------------

**R1:** The tl_base_pa address must be at a 16-byte boundary.

**R2:** All fields defined in this specification must be stored in memory with little-endian byte order.

**R3:** The base address of a TE must be the 16-byte aligned address immediately after the end of the previous entry (or TL header, if the TE is the first entry on the TL).


Transfer list header
--------------------

A TL must begin with a TL header. The layout of the TL header is shown in
:numref:`tab_tl_header`.  The presence of a TL header can be verified by
inspecting the signature field which must contain the 0x6e_d0ff value.  The
version field determines the contents of the handoff start header.

.. _tab_tl_header:
.. list-table:: TL header
   :widths: 2 2 2 8

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - signature
     - 0x4
     - 0x0
     - The value of signature must be 0x6e_d0ff.

   * - checksum
     - 0x1
     - 0x4
     - The checksum is used to ensure the data contained within the list is intact. The checksum is set to a value such that the sum over every byte in the {tl_base_pa, …, tl_base_pa + size -1} address range, modulo 256, is equal to 0.

   * - reserved
     - 0x3
     - 0x5
     - Reserved, must be zero.

   * - version
     - 0x4
     - 0x8
     - The version of the TL header. This field is set to 1 for the TL header layout described in this version of the table.

   * - hdr_size
     - 0x4
     - 0xc
     - The size of this TL header in bytes. This field is set to 0x20 for the TL header layout described in this version of the table.

   * - size
     - 0x4
     - 0x10
     - The number of bytes occupied by the TL. This field accounts for the size of the TL header plus the size of all the entries contained in the TL. This field must be updated when any entry is added to the TL.

   * - max_size
     - 0x4
     - 0x14
     - The maximum number of bytes that the TL can occupy. Any entry producer must check if there is sufficient space before adding an entry to the list. Firmware can resize and/or relocated the TL and update this field accordingly, provided that the TL requirements are respected.

   * - reserved
     - 0x8
     - 0x18
     - Reserved, must be zero.


.. _sec_tl_entry_hdr:

TL entry header
---------------

All TEs start with an entry header followed by a data section.

Note: the size of an entry (hdr_size + data_size) is not mandatorily a 16-byte
multiple. When traversing the TL firmware must compute the next TE address following
R3.

For example, assume the current TE address is *cur_base_addr* and its size is
*cur_entry_size*.  Using C language notation, a derivation of the base address of
the next TE (next_base_addr) is the following:

.. code-block:: C

   next_base_addr = (cur_base_addr + cur_entry_size + 0xf) & ~((uintptr_t)0xf)

The TE header is defined in :numref:`tab_te_header`.

.. _tab_te_header:

.. list-table:: TE header
   :widths: 2 2 2 8

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x4
     - 0x0
     - The entry type identifier.

   * - hdr_size
     - 0x4
     - 0x4
     - The size of this entry header in bytes.

   * - data_size
     - 0x4
     - 0x8
     - The size of the data content in bytes.

   * - reserved
     - 0x4
     - 0xc
     - Reserved, must be zero.


Entry type ranges
-----------------

The content of the data section is determined by the tag id. The tag id space contains two ranges:

 #. Standard range, and
 #. Non-standard range

The *tag_id* ranges are described in :numref:`tab_tag_id_ranges`.

.. _tab_tag_id_ranges:

.. list-table:: Tag ID ranges
   :widths: 3 8

   * - tag ID range
     - Description

   * - 0x0 -- 0xf_ffff
     - Standard tag id range. Any tag id in this range must first be allocated in this specification before being used. The allocation of the tag id requires the entry layout to be defined as well.


   * - 0x10_0000 -- 0x10_ffff
     - Non-standard range. A platform firmware integrator can create entries in this range. Different platforms are allowed to have tag ids in this range with distinct data formats. Entries in this range are not standardized.

   * - 0x11_0000 -- 0xffff_ffff
     - Reserved

.. _sec_std_entries:

Standard transfer entries
-------------------------

The TEs have a *tag_id* in the {0, ..., 0xf_ffff} set. Both
the tag_id of a standard entry as well as the entry layout
must be defined in this specification before being used.
New entries are expected to have a simple layout. Complex
data should be represented in a self-describing data
structure, such as the FDT [DT]_.

The following entry types are currently defined:

- empty entry: tag_id = 0  (:numref:`void_entry`).
- fdt entry: tag_id = 1  (:numref:`fdt_entry`).
- single HOB block entry: tag_id = 2 (:numref:`hob_block_entry`).
- HOB list entry: tag_id = 3 (:numref:`hob_list_entry`).
- ACPI table aggregate entry: tag_id = 4 (:numref:`acpi_aggr_entry`).

All other standard *tag_id* values are reserved by this specification.

.. _void_entry:

Empty entry layout (XFERLIST_VOID)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The empty or void entry should not contain any information to be consumed by any firmware stage.
The intent of the void entry type is for information to be removed from the list without subsequent entries having to be relocated.

.. _tab_void:
.. list-table:: Empty type layout
   :widths: 2 2 2 8

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x4
     - 0x0
     - The tag_id field must be set to **0**.

   * - hdr_size
     - 0x4
     - 0x4
     - The size of this entry header in bytes.

   * - data_size
     - 0x4
     - 0x8
     - The size of the data content in bytes.

   * - reserved
     - 0x4
     - 0xc
     - Reserved, must be zero.

   * - void_data
     - data_size
     - hdr_size
     - Void content


.. _fdt_entry:

FDT entry layout (XFERLIST_FDT)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The fdt is defined in [DT]_. The FDT TE contains the fdt in the data section.
The intent of the FDT entry is to carry the hardware description devicetree in
the flattened devicetree (FDT) [DT]_ representation.

.. _tab_fdt:
.. list-table:: FDT type layout
   :widths: 2 2 2 8

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x4
     - 0x0
     - The tag_id field must be set to **1**.

   * - hdr_size
     - 0x4
     - 0x4
     - The size of this entry header in bytes.

   * - data_size
     - 0x4
     - 0x8
     - The size of the data content in bytes.

   * - reserved
     - 0x4
     - 0xc
     - Reserved, must be zero.

   * - fdt
     - data_size
     - hdr_size
     - The fdt field contains the hardware description fdt.


.. _hob_block_entry:

HOB block entry layout (XFERLIST_HOB_B)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The HOB is defined in [PI]_. This entry type encapsulates a single HOB block.
The intent of the HOB block entry is to hold a single HOB block. A complete HOB
list can then be constructed, by a receiver, by obtaining all the HOB blocks in
the TL and following the HOB list requirements defined in [PI]_.

.. _tab_hob_block:
.. list-table:: HOB block type layout
   :widths: 2 2 2 8

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x4
     - 0x0
     - The tag_id field must be set to **2**.

   * - hdr_size
     - 0x4
     - 0x4
     - The size of this entry header in bytes.

   * - data_size
     - 0x4
     - 0x8
     - The size of the data content in bytes.

   * - reserved
     - 0x4
     - 0xc
     - Reserved, must be zero.

   * - hob_block
     - data_size
     - hdr_size
     - Holds a single HOB block.


.. _hob_list_entry:

HOB list entry layout (XFERLIST_HOB_L)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The HOB list is defined in [PI]_. The HOB list starts with a PHIT block and can
contain an arbitrary number of HOB blocks. This entry type encapsulates a
complete HOB list.  An enclosed HOB list must respect the HOB list constraints
specified in [PI]_.

.. _tab_hob_list:
.. list-table:: HOB list type layout
   :widths: 2 2 2 8

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x4
     - 0x0
     - The tag_id field must be set to **3**.

   * - hdr_size
     - 0x4
     - 0x4
     - The size of this entry header in bytes.

   * - data_size
     - 0x4
     - 0x8
     - The size of the data content in bytes.

   * - reserved
     - 0x4
     - 0xc
     - Reserved, must be zero.

   * - hob_list
     - data_size
     - hdr_size
     - Holds a complete HOB list.


.. _acpi_aggr_entry:

ACPI table aggregate entry layout (XFERLIST_ACPI_AGGR)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This entry type holds one or more ACPI tables. The first table must start at
offset *hdr_size*, from the start of the entry. Any subsequent ACPI tables
must be located at the next 16-byte alligned address following the preceding
ACPI table. Note that each ACPI table has a *Length* field in the ACPI table
header [ACPI]_, which must be used to determine the end of the ACPI table.
The *data_size* value must be set such that the last ACPI table, in this entry,
ends at offset *hdr_size + data_size*, from the start of the entry.

.. _tab_acpi_aggr:
.. list-table:: ACPI table aggregate type layout
   :widths: 2 2 2 8

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x4
     - 0x0
     - The tag_id field must be set to **4**.

   * - hdr_size
     - 0x4
     - 0x4
     - The size of this entry header in bytes.

   * - data_size
     - 0x4
     - 0x8
     - The size of the data content in bytes.

   * - reserved
     - 0x4
     - 0xc
     - Reserved, must be zero.

   * - acpi_tables
     - data_size
     - hdr_size
     - One or more ACPI tables.
