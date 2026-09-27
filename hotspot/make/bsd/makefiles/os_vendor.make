#
# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
#
# This code is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 2 only, as
# published by the Free Software Foundation.
#
# This code is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# version 2 for more details (a copy is included in the LICENSE file that
# accompanied this code).
#
# You should have received a copy of the GNU General Public License version
# 2 along with this work; if not, write to the Free Software Foundation,
# Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
# or visit www.oracle.com if you need additional information or have any
# questions.
#

# OS_VENDOR is the operating system the VM is built for, spelled the way
# its uname -s spells it.  uname names the machine running make, which is
# not that one when the VM is cross-compiled, so take configure's word for
# the target where there is a spec and ask uname only where there is not.

ifeq ($(OPENJDK_TARGET_OS_VENDOR), netbsd)
  OS_VENDOR := NetBSD
else ifeq ($(OPENJDK_TARGET_OS_VENDOR), freebsd)
  OS_VENDOR := FreeBSD
else ifeq ($(OPENJDK_TARGET_OS_VENDOR), openbsd)
  OS_VENDOR := OpenBSD
else ifeq ($(OPENJDK_TARGET_OS_VENDOR), dragonfly)
  OS_VENDOR := DragonFly
else ifeq ($(OPENJDK_TARGET_OS), macosx)
  OS_VENDOR := Darwin
else
  OS_VENDOR := $(shell uname -s)
endif
