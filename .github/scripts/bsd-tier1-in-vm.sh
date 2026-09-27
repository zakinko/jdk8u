#!/bin/sh
# Copyright (c) 2026, Oracle and/or its affiliates. All rights reserved.
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
#
# This code is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 2 only, as
# published by the Free Software Foundation.  Oracle designates this
# particular file as subject to the "Classpath" exception as provided
# by Oracle in the LICENSE file that accompanied this code.
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

# Runs one part of tier1 inside a BSD virtual machine, against the image a
# cross build uploaded, from the root of the workspace the VM was handed.
# test-bsd.yml boots the machine; this is what it runs there.
#
# Usage: bsd-tier1-in-vm.sh <jdk|langtools|hotspot> <test or :group>...
#
# jtreg is run directly rather than through the test makefiles, which ask
# uname for the platform and know none of these systems.  The options are
# the ones those makefiles pass.
#
# It returns 0 when the tests ran, whatever they found: the VM actions copy
# the workspace back out only when their step succeeds, so a failing exit
# here would throw away the files the failure has to be read from.  jtreg's
# exit status goes to build/jtreg-exit, and test-bsd.yml reads it.

set -e
repo="$1"
shift
PATH=/usr/pkg/bin:/usr/pkg/sbin:/usr/local/bin:/usr/local/sbin:$PATH
export PATH

rm -rf jdk8 build
mkdir -p jdk8 build
tar -xzf bundle/jdk-*.tar.gz -C jdk8
JDK="$PWD/jdk8/j2sdk-image"
JT="$PWD/jtreg"
chmod +x "$JT"/bin/*
os=`uname -s`

if [ "$os" = NetBSD ]; then
  # A JDK built on NetBSD is marked as it is linked; one cross-built from
  # Linux cannot be, because paxctl(8) only exists here.  Without the mark
  # every launcher dies in VM initialisation, because PaX refuses the
  # writable and executable mapping the JIT asks for.
  find "$JDK" -type f \( -perm -u+x -o -name '*.so' \) -print |
    while read f; do /usr/sbin/paxctl +m "$f" >/dev/null 2>&1 || :; done
fi

if [ "$os" = OpenBSD ]; then
  # The JVM reserves its heap and code cache up front, well past the
  # default data size limit of a login class.
  ulimit -Sd `ulimit -Hd`
fi

# A crashing test leaves an hs_err file; a core of a 2GB heap on top of it
# only fills the disk.
ulimit -c 0

# What the launcher asks the run-time linker for, so a missing library is
# named here rather than read out of a test log.
echo "--- what the VM sees ---"
uname -a
ldd "$JDK/bin/java" 2>&1 | head -12
echo "--- end ---"

if ! "$JDK/bin/java" -version; then
  echo "the image does not start here; no test can run"
  echo 99 > build/jtreg-exit
  exit 0
fi

# jdk/test/Makefile gives each test VM 512MB and has the only headful
# key; the image is headless, so those tests cannot run.
extra=
if [ "$repo" = jdk ]; then
  extra="-vmoption:-Xmx512m -k:!headful"
fi
if [ -f "$PWD/$repo/test/ProblemList.txt" ]; then
  extra="$extra -exclude:$PWD/$repo/test/ProblemList.txt"
fi

set +e
JT_JAVA="$JDK/bin/java" "$JT/bin/jtreg" \
  -jdk:"$JDK" \
  -dir:"$PWD/$repo/test" \
  -w:"$PWD/build/work" \
  -r:"$PWD/build/report" \
  -agentvm -a -ignore:quiet \
  -v:fail,error,summary -retain:fail,error \
  -timeoutFactor:4 -conc:3 \
  $extra \
  "$@"
echo $? > build/jtreg-exit
set -e

echo "--- jtreg exited `cat build/jtreg-exit` ---"
cat build/report/text/summary.txt 2>/dev/null | grep -v 'Passed\.' || :
exit 0
