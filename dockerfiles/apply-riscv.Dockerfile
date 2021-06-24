#
# Copyright 2020, Data61/CSIRO
#
# SPDX-License-Identifier: BSD-2-Clause
#

# The RISC-V toolchain is now part of the seL4 base image.
# We still provide the -riscv combination for backwards compatibility with existing CI.

FROM trustworthysystems/sel4

LABEL ORGANISATION="Trustworthy Systems"
LABEL MAINTAINER="Gerwin Klein <gerwin.klein@proofcraft.systems>"
