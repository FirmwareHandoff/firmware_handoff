.. SPDX-License-Identifier: CC-BY-SA-4.0
.. SPDX-FileCopyrightText: Copyright The Firmware Handoff Specification Contributors

.. default-role:: code

.. _sec_tl:

Transfer list
=============

The TL is composed of a TL header which is followed by sequence of Transfer
Entries (TE). The whole TL is contiguous in physical address space. The TL
header and all the TEs are 8-byte aligned (we use `align8()` to denote this).
The TL header specifies the number of bytes occupied by the
TL. The TEs are defined in :numref:`sec_tl_entry_hdr` and
:numref:`sec_std_entries`. Each TE carries a header which contains an
identifier, `tag_id`, that is used to determine the content of the associated
TE. The TL header is located at `tl_base_pa`. The `tl_base_pa` is passed in the
register allocated for that handoff boundary (as specified in
:numref:`handoff_arch_bindings`). A
depiction of the TL is present in :numref:`fig_list` , there the first TE in
the list (TE[0]) is shown to start at the end of the TL header
(`tl_base_pa + 8`). The second TE in the list (TE[1]) starts at the next multiple
of 8, after the end of the TE[0].


.. _fig_list:
.. figure:: images/handoff_list_diagram.svg
   :alt: Transfer list example
   :scale: 85%

   Transfer list example

Transfer list requirements
--------------------------

**R1:** The tl_base_pa address must be at a 8-byte boundary.

**R2:** All fields defined in this specification must be stored in memory with little-endian byte order.

**R3:** The base address of a TE must be the 8-byte aligned address immediately after the end of the previous entry (or TL header, if the TE is the first entry on the TL).

**R4:** When relocating the TL, the offset from `tl_base_pa` to the nearest alignment boundary specified by the `alignment` field in the TL header must be preserved.

**R5:** If a TE type definition contains a sub-type field, then multiple entries of that TE type are allowed in the TL. The TE must have unique values in the sub-type field.

**R6:** A TL must contain at most one entry of each TE type that lacks a sub-type field.

Transfer list header
--------------------

A TL must begin with a TL header. The layout of the TL header is shown in
:numref:`tab_tl_header`.  The presence of a TL header can be verified by
inspecting the signature field which must contain the 4a0f_b10b value.  The
version field determines the contents of the handoff start header. The version
will only be changed by an update to this specification when new TL header or
TE header fields are defined (i.e. not when allocating new tag IDs), and all
changes will be backwards-compatible to older readers.

.. _tab_tl_header:
.. list-table:: TL header
   :widths: 2 2 2 9

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - signature
     - 0x4
     - 0x0
     - The value of signature must be `4a0f_b10b`.

   * - checksum
     - 0x1
     - 0x4
     - If enabled by the flags, the checksum is used to provide basic protection against something overwriting the TL in memory. The checksum is set to a value such that the xor over every byte in the {`tl_base_pa`, …, `tl_base_pa + used_size - 1`} address range, is equal to 0. For the purposes of this calculation, the value of this checksum field in the TL header must be assumed as 0. Note that the checksum includes the TL header, all TEs and the inter-TE padding, but not the range reserved for future TE additions up to total_size. The values of inter-TE padding bytes are not defined by this specification and may be uninitialized memory. (This means that multiple TLs with exactly the same size and contents may still have different checksum values.). If checksums are not used, this must be 0.

   * - version
     - 0x1
     - 0x5
     - The version of the TL header. This field is set to |current_version| for the TL header layout described in this version of the table. Code that encounters a TL with a version higher than it knows to support may still read the TL and all its TEs, and assume that it is backwards-compatible to previous versions (ignoring any extra bytes in a potentially larger TL or TE header). However, code may not append new entries to a TL unless it knows how to append entries for the specified version.

   * - hdr_size
     - 0x1
     - 0x6
     - The size of this TL header in bytes. This field is set to 0x18 for the TL header layout described in this version of the table.

   * - alignment
     - 0x1
     - 0x7
     - The maximum alignment required by any TE in the TL, specified as a power of two. For a newly created TL, the alignment requirement is 8 so this value should be set to 3. It should be updated whenever a new TE is added with a larger requirement than the current value.

   * - used_size
     - 0x4
     - 0x8
     - The number of bytes within the TL that are used by TEs. This field accounts for the size of the TL header plus the size of all the entries contained in the TL. It must be a multiple of 8 (i.e. it includes the inter-TE padding after the end of the last TE). This field must be updated when any entry is added to the TL.

   * - total_size
     - 0x4
     - 0xc
     - The number of bytes occupied by the entire TL, including any spare space at the end, after `used_size`. Any entry producer must check if there is sufficient space before adding an entry to the list. Firmware can resize and/or relocate the TL and update this field accordingly, provided that the TL requirements are respected. This field must be a multiple of 8.

   * - flags
     - 0x4
     - 0x10
     - Flags word. See below for contents.

   * - reserved
     - 0x4
     - 0x14
     - Reserved word. Must be set to 0 or ignored.


TL Flags
^^^^^^^^

The TL flags word is intended to signal properties relating to the TL as a
whole. Future flag values may be added according to the rules of the `version`
field.

.. list-table:: Flags
   :widths: 2 2 8

   * - Bit
     - Name
     - Description

   * - 0
     - has_checksum
     - A value of `1` (true) indicates that this TL uses checksums. The checksum
       field must be valid at the point of handoff.

   * - 31:1
     - unused
     - Reserved for future use. Must be 0 or ignored.


.. _sec_tl_entry_hdr:

TL entry header
---------------

All TEs start with an entry header followed by a data section.

Note: the size of an entry (hdr_size + data_size) is not mandatorily an 8-byte
multiple. When traversing the TL firmware must compute the next TE address following
R3.

For example, assume the current TE is `te` and its address is `te_base_addr`.  Using
C language notation, a derivation of the base address of the next TE
(next_base_addr) is the following:

.. code-block:: C

   next_base_addr = align8(te_base_addr + te.hdr_size + te.data_size)

The TE header is defined in :numref:`tab_te_header`.

.. _tab_te_header:

.. list-table:: TE header
   :widths: 2 2 2 8

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x3
     - 0x0
     - The entry type identifier.

   * - hdr_size
     - 0x1
     - 0x3
     - The size of this entry header in bytes. This field is set to 8 for the TE header layout described in this version of the table.

   * - data_size
     - 0x4
     - 0x4
     - The exact size of the data content in bytes, not including inter-TE padding. May be 0.


TL Contents
-----------

Tags are expected to have a simple layout (representable by a C structure) and
each tag should only represent data for a single logical concept. Data for
multiple distinct concepts should be split across different tags, even if
they're always expected to appear together on the first platform adding the tag
(to encourage reusability in different situations). Alternatively, complex data
may be represented in a different kind of well-established handoff data
structure (e.g. FDT [DT]_, HOB [PI]_) that is inserted into the TL as a single
TE. The same tag ID may occur multiple times in the TL to represent multiple
instances of the same kind of object. Tag layouts (including the meaning of all
fields) are considered stable after being added to this specification and may
never be changed in a backwards-incompatible way. If a backwards-incompatible
change is desired, a new tag ID should be allocated for the new version of the
layout instead.

Tag layouts may be changed in a backwards-compatible manner by allowing new
valid values in existing fields (including reserved fields), as long as the
original layout definition clearly defined how unknown values in those fields
should be handled, and the rest of the TE would still be considered valid and
correct for older readers that consider the new values unknown. TE layouts may
also be expanded by adding new fields at the end, with the same restrictions.
TEs should not contain explicit version numbers and instead just use the
`data_size` value to infer how many fields exist. TE layouts which have been
changed like this must clearly document which fields or valid values were added
at a later time, and in what order.

The TL must not hold pointers or addresses within its entries, which refer to
anything in the TL. These can make it difficult to relocate the TL. TL
relocation typically happens in later phases of the boot when there is more
memory available, which is needed for adding larger entries.

The TL may hold pointers or addresses which refer to regions outside the TL, if
this is necessary. For example, the MMIO address of a device may be included in
a TE. But in general, pointers and addresses should be avoided. Instead, the
data structure itself should generally be contained within the TL. This approach
provides the greatest flexibility for later boot stages to handle memory as they
wish, since relocating the TL is fairly simple and self-contained, without
needing to consider relocating other data structures strewn around the memory.

Where pointers or addresses are needed due to some project-specific restriction,
a separate TE should generally be created for that purpose, rather than mixing
pointers with other data. Of course there may be exceptions where two pointers
belong together, or there is a pointer and a size which belong together. In any
case, the PR should clearly document the need for these pointers.


Entry-type allocation
---------------------

Tag IDs must be allocated in this specification before use. A new tag ID can be
allocated by submitting a pull request to this repository that adds a
description of the respective TE data layout to this specification. Tag IDs do
not have to be allocated in order. Submitters are encouraged to try to group
tag IDs together in logical clusters at 16 or 256-aligned boundaries (e.g. all
tags related to a particular chipset or to a particular firmware project could
use adjacent tag numbers), but there are no predefined ranges and no
reservations of tag ranges for specific use.

The {0xff_f000, ..., 0xff_ffff} range is reserved for non-standardized use.
Anyone is free to use tags from that range for any custom TE layout without
adding their definitions to this specification first. The use of this range is
*strongly discouraged* for anything other than local experiments or code that
will only ever be used in closed-source components owned by the entity
controlling the entire final firmware image. In particular, a TE just
containing platform-specific data or internal structures specific to a single
firmware implementation is no reason not to allocate a standardized tag for it
in this specification. Since standards often emerge organically, the goal is to
create unique tag IDs for everything just in case it turns out to be useful in
more applications than initially anticipated. Basically, whenever you're
submitting code for a new TE layout to any public open-source project, that's
probably a good indication that you should allocate a tag ID for it in this
specification.

.. _tab_tag_id_ranges:

.. list-table:: Tag ID ranges
   :widths: 3 8

   * - tag ID range
     - Description

   * - 0x0 -- 0x7f_ffff
     - Standardized range. Any tag ID in this range must first be allocated in this specification before being used. The allocation of the tag ID requires the entry layout to be defined as well.

   * - 0x80_0000 -- 0xff_efff
     - Reserved. (Can later be used to extend standardized range if necessary.)

   * - 0xff_f000 -- 0xff_ffff
     - Non-standardized range. Tag IDs in this range can be used without allocation in this specification. Using this range for anything other than local experimentation or closed-source components that are entirely under the control of a single platform firmware integrator is strongly discouraged. Tags in this range are not tracked in this repository and PRs to add tag defintions for this range will not be accepted.


.. _sec_operations:

Standard operations
-------------------

This section describes the valid operations that can be performed on a TL in
more detail, in order to clarify how to use the various fields and to serve as a
guideline for implementation.

Validating a TL header
^^^^^^^^^^^^^^^^^^^^^^

.. default-role:: code

Inputs:

- `tl_base_addr`: Base address of the existing TL.

#. Compare `tl.signature` (`tl_base_addr + 0x0`) to `4a0f_b10b`. On a mismatch,
   abort (this is not a valid TL).

#. Compare `tl.version` (`tl_base_addr + 0x5`) to the expected version
   (currently |current_version|). If there is an exact match, the TL is valid
   for all operations outlined in this section. If `tl.version` is larger, the
   TL is valid for reading but must not be modified or relocated. If
   `tl.version` is smaller, either abort or switch to code designed to
   interpret the respective previous version of this specification (note that
   the version number `0x0` is illegal and processing should always abort if it
   is found).

#. *(optional)* Check that `tl.used_size` (`tl_base_addr + 0x8`) is smaller or equal
   to `tl.total_size` (`tl_base_addr + 0xc`), and that `tl.total_size` is smaller or
   equal to the size of the total area reserved for the TL (if known). If not,
   abort (TL is corrupted).

#. *(optional)* If `has_checksum`, check that the xor of `tl.used_size` bytes
   starting at `tl_base_addr` is 0x0. If not, abort (TL is corrupted).

Reading a TL
^^^^^^^^^^^^

Inputs:

- `tl_base_addr`: Base address of the existing TL.

#. Calculate `te_base_addr` as `align8(tl_base_addr + tl.hdr_size)`. (Do not
   hardcode the value for `tl.hdr_size`!)

#. While `te_base_addr - tl_base_addr` is smaller or equal to `tl.used_size`:

   #. *(optional)* Check that `te_base_addr + te.hdr_size + te.data_size - tl_base_addr`
      is smaller or equal to `tl.used_size`, otherwise abort (the TL is corrupted).

   #. If `te.tag_id` (`te_base_addr + 0x0`) is a known tag, interpret the data
      at `te_base_addr + te.hdr_size` accordingly. (Do not hardcode the value
      for `te.hdr_size`, even for known tags!) Otherwise, ignore the tag and
      proceed with the next step.

   #. Add `align8(te.hdr_size + te.data_size)` to `te_base_addr`.

Adding a new TE
^^^^^^^^^^^^^^^

Inputs:

- `tl_base_addr`: Base address of the TL to add a TE to.
- `new_tag_id`: ID number of the tag for the new TE.
- `new_data_size`: Size in bytes of the data to be encapsulated in the TE.
- [data]: Data to be copied into the TE or generated on the fly.

#. *(optional)* Follow the steps in `Reading a TL`_ to look for a TE where
   `te.tag_id` is `0x0` (XFERLIST_VOID) and `te.data_size` is greater or equal
   to `new_data_size`. If found:

   #. Remember `te.data_size` as `old_void_data_size`.

   #. Use the `te_base_addr` of this tag for the rest of the operation.

   #. If `has_checksum`, xor the `align8(new_data_size + 0x8)` bytes starting at
      `te_base_addr` with `tl.checksum`.

   #. Skip the next step (step 2) with all its substeps.

#. Calculate `te_base_addr` as `tl_base_addr + tl.used_size`.

   #. If `tl.total_size - tl.used_size` is smaller than `align8(new_data_size + 0x8)`,
      abort (not enough room to add TE).

   #. If `has_checksum`, xor the 4 bytes from `tl_base_addr + 0x8` with
      `tl_base_addr + 0xc` from `tl.checksum`.

   #. Add `align8(new_data_size + 0x8)` to `tl.used_size`.

   #. If `has_checksum`, xor the 4 bytes from `tl_base_addr + 0x8` to
      `tl_base_addr + 0xc` with `tl.checksum`.

#. Set `te.tag_id` (`te_base_addr + 0x0`) to `new_tag_id`.

#. Set `te.hdr_size` (`te_base_addr + 0x3`) to `8`.

#. Set `te.data_size` (`te_base_addr + 0x4`) to `new_data_size`.

#. Copy or generate the TE data into `te_base_addr + 0x8`.

#. If `has_checksum`, xor the `align8(new_data_size + 0x8)` bytes starting at
   `te_base_addr` with `tl.checksum`.

#. If an existing XFERLIST_VOID TE was chosen to be overwritten in step 1, and
   `old_void_data_size - new_data_size` is greater or equal to `0x8`:

   #. Use `te_base_addr + align8(new_data_size + 0x8)` as the new `te_base_addr`
      for a new XFERLIST_VOID tag.

   #. If `has_checksum`, xor the 8 bytes from `te_base_addr` to
      `te_base_addr + 0x8` with `tl.checksum`.

   #. Set `te.tag_id` (`te_base_addr + 0x0`) to `0x0` (XFERLIST_VOID).

   #. Set `te.hdr_size` (`te_base_addr + 0x3`) to `0x8`.

   #. Set `te.data_size` (`te_base_addr + 0x4`) to
      `old_void_data_size - align8(new_data_size) - 0x8`.

   #. If `has_checksum`, xor the 8 bytes from `te_base_addr` to
      `te_base_addr + 0x8` with `tl.checksum`.

Adding a new TE with special data alignment requirement
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Inputs:

- `tl_base_addr`: Base address of the TL to add a TE to.
- `new_tag_id`: ID number of the tag for the new TE.
- `new_alignment`: The alignment boundary as a power of 2 that the data must be aligned to.
- `new_data_size`: Size in bytes of the data to be encapsulated in the TE.
- [data]: Data to be copied into the TE or generated on the fly.

#. Calculate `alignment_mask` as `(1 << new_alignment) - 1`.

#. If `(tl_base_addr + tl.used_size + 0x8) & alignment_mask` is not `0x0`, follow the
   steps in `Adding a new TE`_ with the following inputs (bypass the option to
   overwrite an existing XFERLIST_VOID TE):

   #. `tl_base_addr` remains the same

   #. `new_tag_id` is `0x0` (XFERLIST_VOID)

   #. `new_data_size` is `(1 << new_alignment) - ((tl_base_addr + tl.used_size + 0x8) & alignment_mask) - 0x8`.

   #. No data (i.e. just don't touch the bytes that form the data portion for this TE).

#. Follow the steps in `Adding a new TE`_ with the original inputs (again bypass
   the option to overwrite an existing XFERLIST_VOID TE).

#. If `new_alignment` is larger than `tl.alignment`:

   #. If `has_checksum`, xor `tl.alignment` with `tl.checksum`.

   #. Set `tl.alignment` to `new_alignment`.

   #. If `has_checksum`, xor `tl.alignment` with `tl.checksum`.

Creating a TL
^^^^^^^^^^^^^

Inputs:

- `tl_base_addr`: Base address where to place the new TL.
- `available_size`: Available size in bytes to reserve for the TL after `tl_base_addr`.

#. Check that `available_size` is larger than `0x18` (the assumed `tl.hdr_size`), otherwise abort.

#. Set `tl.signature` (`tl_base_addr + 0x0`) to `4a0f_b10b`.

#. Set `tl.checksum` (`tl_base_addr + 0x4`) to `0x0` (for now).

#. Set `tl.version` (`tl_base_addr + 0x5`) to |current_version|.

#. Set `tl.hdr_size` (`tl_base_addr + 0x6`) to `0x18`.

#. Set `tl.alignment` (`tl_base_addr + 0x7`) to `0x3`.

#. Set `tl.used_size` (`tl_base_addr + 0x8`) to `0x18` (the assumed `tl.hdr_size`).

#. Set `tl.total_size` (`tl_base_addr + 0xc`) to `available_size`.

#. If checksums are to be used, set `tl.flags` (`tl_base_addr + 0x10`) to `1`,
   else `0`. This is the value of `has_checksum`.

#. If `has_checksum`, calculate the checksum as the xor of all bytes from
   `tl_base_addr` to `tl_base_addr + tl.hdr_size`, and write the result to
   `tl.checksum`.

Relocating a TL
^^^^^^^^^^^^^^^

Inputs:

- `tl_base_addr`: Base address of the existing TL.
- `target_base`: Base address of the target region to relocate into.
- `target_size`: Size in bytes of the target region to relocate into.

#. Calculate `alignment_mask` as `(1 << tl.alignment) - 1`.

#. Calculate the current `alignment_offset` as `tl_base_addr & alignment_mask`.

#. Calculate `new_tl_base` as `(target_base & ~alignment_mask) + alignment_offset`.

#. If `new_tl_base` is below `target_base`, add `alignment_mask + 1` to `new_tl_base`.

#. If `new_tl_base - target_base + tl.used_size` is larger than `target_size`, abort
   (not enough space to relocate).

#. Copy `tl.used_size` bytes from `tl_base_addr` to `new_tl_base`.

#. If `has_checksum`, xor the the 4 bytes from `new_tl_base + 0xc`
   to `new_tl_base + 0x10` with `tl.checksum` (`new_tl_base + 0x4`).

#. Set `tl.total_size` (`new_tl_base + 0xc`) to `target_size - (new_tl_base - target_base)`.

#. If `has_checksum`, xor the 4 bytes from `new_tl_base + 0xc` to
   `new_tl_base + 0x10` with `tl.checksum` (`new_tl_base + 0x4`).


.. _sec_std_entries:

Standard transfer entries
-------------------------

The following entry types are currently defined:

- empty entry: tag_id = 0  (:numref:`void_entry`).
- fdt entry: tag_id = 1  (:numref:`fdt_entry`).
- single HOB block entry: tag_id = 2 (:numref:`hob_block_entry`).
- HOB list entry: tag_id = 3 (:numref:`hob_list_entry`).
- ACPI table aggregate entry: tag_id = 4 (:numref:`acpi_aggr_entry`).
- TPM event log entry: tag_id = 5 (:numref:`tpm_evlog_entry`).
- TPM CRB base entry: tag_id = 6 (:numref:`tpm_crb_base_entry`).
- Entries related to Trusted Firmware (:numref:`tf_entries`).

.. _void_entry:

Empty entry layout (XFERLIST_VOID)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The empty or void entry should not contain any information to be consumed by any firmware stage.
The intent of the void entry type is to remove information from the list without needing to
relocate subsequent entries, or to create padding for entries that require a specific alignment.
Void entries may be freely overwritten with new TEs, provided the resulting TL remains valid
(i.e. a void entry can only be overwritten by a TE of equal or smaller size; if the size is more
than 8 bytes smaller, a new void entry must be created behind the new TE to cover the remaining
space up to the next TE).

.. _tab_void:
.. list-table:: Empty type layout
   :widths: 2 2 2 8

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x3
     - 0x0
     - The tag_id field must be set to **0**.

   * - hdr_size
     - 0x1
     - 0x3
     - |hdr_size_desc|

   * - data_size
     - 0x4
     - 0x4
     - The size of the void space in bytes. May be 0. For XFERLIST_VOID,
       data_size *MUST* be a multiple of 8 (i.e. there must be no space left to
       inter-TE padding after this TE).

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
     - 0x3
     - 0x0
     - The tag_id field must be set to **1**.

   * - hdr_size
     - 0x1
     - 0x3
     - |hdr_size_desc|

   * - data_size
     - 0x4
     - 0x4
     - The size of the FDT in bytes.

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
     - 0x3
     - 0x0
     - The tag_id field must be set to **2**.

   * - hdr_size
     - 0x1
     - 0x3
     - |hdr_size_desc|

   * - data_size
     - 0x4
     - 0x4
     - The size of the HOB block in bytes.

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
     - 0x3
     - 0x0
     - The tag_id field must be set to **3**.

   * - hdr_size
     - 0x1
     - 0x3
     - |hdr_size_desc|

   * - data_size
     - 0x4
     - 0x4
     - The size of the HOB list in bytes.

   * - hob_list
     - data_size
     - hdr_size
     - Holds a complete HOB list.


.. _acpi_aggr_entry:

ACPI table aggregate entry layout (XFERLIST_ACPI_AGGR)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This entry type holds one or more ACPI tables. The first table must start at
offset `hdr_size` from the start of the entry. Since ACPI tables usually have an
alignment requirement larger than 8, writers may first need to create an
XFERLIST_VOID padding entry so that the subsequent `te_base_addr + te.hdr_size`
will be correctly aligned. Any subsequent ACPI tables must be located at the
next 16-byte alligned address following the preceding ACPI table. Note that each
ACPI table has a `Length` field in the ACPI table header [ACPI]_, which must be
used to determine the end of the ACPI table.  The `data_size` value must be set
such that the last ACPI table in this entry ends at offset
`hdr_size + data_size` from the start of the entry.

.. _tab_acpi_aggr:
.. list-table:: ACPI table aggregate type layout
   :widths: 2 2 2 8

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x3
     - 0x0
     - The tag_id field must be set to **4**.

   * - hdr_size
     - 0x1
     - 0x3
     - |hdr_size_desc|

   * - data_size
     - 0x4
     - 0x4
     - The size of all included ACPI tables + padding in bytes.

   * - acpi_tables
     - data_size
     - hdr_size
     - One or more ACPI tables.


.. _tpm_evlog_entry:

TPM event log table entry layout (XFERLIST_EVLOG)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This entry type holds TPM-related information for a platform. The TPM event log
info is a region containing a TPM event log as defined by TCG EFI Protocol
Specification [TCG_EFI]_.

.. _tab_tpm_evlog:
.. list-table:: TPM event log type layout
   :widths: 2 2 4 8

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x3
     - 0x0
     - The tag_id field must be set to **5**.

   * - hdr_size
     - 0x1
     - 0x3
     - |hdr_size_desc|

   * - data_size
     - 0x4
     - 0x4
     - The size of the event log in bytes + sizeof(flags) i.e. 0x4.

   * - flags
     - 0x4
     - hdr_size
     - flags are intended to signal properties of this TE. Bit 0 is
       need_to_replay flag. Some firmware components may compute measurements
       to be extended into a TPM and add them to the TPM event log, but those
       components are unable  to access the TPM themselves. In this case, the
       component should set the "need_to_replay" flag so that the next
       component in the boot chain is aware that the PCRs have not been
       extended. A component with access to the TPM would replay the event log
       by reading each measurement recorded and extending it into the TPM. Once
       the measurements are extended into the TPM, then the "need_to_replay"
       flag must be cleared if the transfer list is passed to additional
       firmware components. Default value is "0". Other bits should be set to
       zero.

   * - event_log
     - data_size - 0x4
     - hdr_size + 0x4
     - Holds a complete event log.


.. _tpm_crb_base_entry:

TPM CRB base address table entry layout (XFERLIST_TPM_CRB_BASE)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The CRB info defines the address of a region of memory that has been carved out
and reserved for use as a TPM Command Response Buffer interface.

.. _tab_tpm_crb_base:
.. list-table:: TPM CRB base type layout
   :widths: 4 2 4 8

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x3
     - 0x0
     - The tag_id field must be set to **6**.

   * - hdr_size
     - 0x1
     - 0x3
     - |hdr_size_desc|

   * - data_size
     - 0x4
     - 0x4
     - This value should be set to **0xc** i.e. sizeof(crb_base_address) + sizeof(crb_size).

   * - crb_base_address
     - 0x8
     - hdr_size
     - The physical base address of a region of memory reserved for use as a
       TPM's Command Response Buffer region.

   * - crb_size
     - 0x4
     - hdr_size + 0x8
     - Size of CRB.


.. _tf_entries:

Entries related to Trusted Firmware
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The following entry types are defined for Trusted Firmware projects,
including TF-A and OP-TEE:

**OP-TEE pageable part address entry layout (XFERLIST_OPTEE_PAGEABLE_PART_ADDR)**

This entry type holds the address of OP-TEE pageable part which is described in
[OPTEECore]_.
This address (of type 'uint64_t') is used when OPTEED (OP-TEE Dispatcher)
is the Secure Payload Dispatcher, indicating where to load the pageable image of
the OP-TEE OS.

.. _tab_optee_pageable_part_address:
.. list-table:: OP-TEE pageable part address type layout
   :widths: 2 2 2 8

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x3
     - 0x0
     - The tag_id field must be set to **0x100**.

   * - hdr_size
     - 0x1
     - 0x3
     - |hdr_size_desc|

   * - data_size
     - 0x4
     - 0x4
     - The size (in bytes) of the address of OP-TEE pageable part which must be set to **8**.

   * - pp_addr
     - 0x8
     - hdr_size
     - Holds the address of OP-TEE pageable part

**DT formatted SPMC manifest entry layout (XFERLIST_DT_SPMC_MANIFEST)**

This entry type holds the SPMC (Secure Partition Manager Core) manifest image
which is in DT format [DT]_ and described in [TFAFFAMB]_.
This manifest contains the SPMC attribute node consumed by the SPMD
(Secure Partition Manager Dispatcher) at boot time.

.. _tab_dt_spmc_manifest:
.. list-table:: DT formatted SPMC manifest type layout
   :widths: 2 2 2 8

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x3
     - 0x0
     - The tag_id field must be set to **0x101**.

   * - hdr_size
     - 0x1
     - 0x3
     - |hdr_size_desc|

   * - data_size
     - 0x4
     - 0x4
     - The size of SPMC manifest in bytes.

   * - spmc_man
     - data_size
     - hdr_size
     - Holds a SPMC manifest image in DT format.

**AArch64 executable entry point information (XFERLIST_EXEC_EP_INFO64)**

This entry type holds the AArch64 variant of `entry_point_info`.
`entry_point_info` is a TF-A-specific data structure [TF_BL31]_ used to
represent the execution state of an image; that is, the state of general purpose
registers, PC, and SPSR.

This information is used by clients to setup the execution environment of
subsequent images. A concrete example is the execution of a bootloader such as
U-Boot in non-secure mode. In TF-A, the runtime firmware BL31 uses an
`entry_point_info` structure corresponding to the bootloader, to setup the
general and special purpose registers. Following conventions
outlined in :ref:`aarch64_receiver`, the general purpose registers consumed
by the bootloader contain the base addresses of the device tree, and transfer
list; along with the transfer list signature.

In practice, control might be transferred from BL31 to any combination of
software running in Secure, Non-Secure, or Realm modes.

.. _tab_entry_point_info:
.. list-table:: Entry point info type layout
   :widths: 2 5 2 6

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x3
     - 0x0
     - The tag_id field must be set to **0x102**.

   * - hdr_size
     - 0x1
     - 0x3
     - |hdr_size_desc|

   * - data_size
     - 0x4
     - 0x4
     - Size of the `entry_point_info` structure in bytes.

   * - ep_info
     - `sizeof(entry_point_info)`
     - hdr_size
     - Holds a single `entry_point_info` structure.

**Read-Write Memory Layout Entry Layout (XFERLIST_RW_MEM_LAYOUT64)**

This entry type holds a structure that describes the layout of a read-write
memory region.

For example, TF-A uses it to convey to BL2 the extent of memory it has available
to perform read-write operations on. BL2 maps the memory described by the layout
into its memory map during platform setup. If other memory types are required
(i.e. read-only memory) separate TE's should be defined.

.. _tab_rw_mem_layout:
.. list-table:: Layout for a RW memory layout entry
   :widths: 2 5 5 6

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x3
     - 0x0
     - The tag_id field must be set to **0x104**.

   * - hdr_size
     - 0x1
     - 0x3
     - |hdr_size_desc|

   * - data_size
     - 0x4
     - 0x4
     - The size of the layout in bytes.

   * - addr
     - 0x8
     - hdr_size
     - The base address of the memory region.

   * - size
     - 0x8
     - hdr_size + 0x8
     - The size of the memory region.

Mbed-TLS heap information (XFERLIST_MBEDTLS_HEAP_INFO)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Specifies the location and size of a memory region, carved out for
stack-based memory allocation in Mbed-TLS. The buffer address and size are
passed to later stages for intialisation of Mbed-TLS.

.. _tab_tpm_crb_base:
.. list-table:: Mbed-TLS heap info type layout
   :widths: 4 2 4 8

   * - Field
     - Size (bytes)
     - Offset (bytes)
     - Description

   * - tag_id
     - 0x3
     - 0x0
     - The tag_id field must be set to **0x105**.

   * - hdr_size
     - 0x1
     - 0x3
     - |hdr_size_desc|

   * - data_size
     - 0x4
     - 0x4
     - This value should be set to **0x10** i.e. sizeof(heap_address) + sizeof(heap_size).

   * - heap_address
     - 0x8
     - hdr_size
     - The address of memory to be used as the heap.

   * - heap_size
     - 0x8
     - hdr_size + 0x8
     - Size of memory region.



.. |hdr_size_desc| replace:: The size of this entry header in bytes must be set to **8**.
.. |current_version| replace:: `0x1`
