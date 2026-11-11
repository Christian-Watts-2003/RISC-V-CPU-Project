# RV32IM pipeline RTL

This folder groups the five-stage pipeline implementation files separately from the legacy single-cycle RTL and its archived reference.

This is an organizational copy of the pipeline `.v` files currently at the `rtl/` root. The root copies have not been deleted because the available repository write interface does not support deleting files. Avoid compiling both `rtl/` and `rtl/pipeline/` recursively in one compilation unit: module names are duplicated.

**Status:** this is not yet a functional processor. The core is still a skeleton; its fetch controls and writeback are not integrated. `muldiv_unit`, pipeline execution, and end-to-end verification are still outstanding. Predecode load-use output is intentionally tied off pending correct IF/ID alignment.
