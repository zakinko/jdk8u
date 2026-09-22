/*
 * Copyright (c) 2002, 2013, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 *
 */

package sun.jvm.hotspot.debugger.bsd;

import sun.jvm.hotspot.debugger.*;

class BsdThread implements ThreadProxy {
    private BsdDebugger debugger;
    private int         thread_id;
    private long        unique_thread_id;

    /** The address argument must be the address of the _thread_id in the
        OSThread. It's value is result ::gettid() call. */
    BsdThread(BsdDebugger debugger, Address threadIdAddr, Address uniqueThreadIdAddr) {
        this.debugger = debugger;
        // FIXME: size of data fetched here should be configurable.
        // However, making it so would produce a dependency on the "types"
        // package from the debugger package, which is not desired.
        this.thread_id = (int) threadIdAddr.getCIntegerAt(0, 4, true);
        this.unique_thread_id = uniqueThreadIdAddr.getCIntegerAt(0, 8, true);
    }

    BsdThread(BsdDebugger debugger, long id) {
        this.debugger = debugger;
        // use unique_thread_id to identify thread
        this.unique_thread_id = id;
        if (!isDarwin()) {
            // On the other BSDs the one id there is, is the lwp id.
            this.thread_id = (int) id;
        }
    }

    public boolean equals(Object obj) {
        if ((obj == null) || !(obj instanceof BsdThread)) {
            return false;
        }

        // Compare the field hashCode() hashes.  This used to compare
        // unique_thread_id while hashCode() returned thread_id, so two proxies
        // for one thread could be equal and still land in different hash
        // buckets -- every HashMap lookup keyed by a thread missed, and pstack
        // printed no thread names and no Java frames.  On the BSDs other than
        // macOS the VM does not set _unique_thread_id (NetBSD and OpenBSD
        // leave it 0), so there every thread compared equal as well; thread_id
        // is the lwp id and identifies the thread on those systems.  macOS
        // keys threads by the mach id in unique_thread_id.
        return isDarwin() ? (((BsdThread) obj).unique_thread_id == unique_thread_id)
                          : (((BsdThread) obj).thread_id == thread_id);
    }

    public int hashCode() {
        return isDarwin() ? Long.hashCode(unique_thread_id) : thread_id;
    }

    private static boolean isDarwin() {
        return sun.jvm.hotspot.utilities.PlatformInfo.getOS().equals("darwin");
    }

    public String toString() {
        return Integer.toString(thread_id) + "/" + Long.toString(unique_thread_id);
    }

    public ThreadContext getContext() throws IllegalThreadStateException {
        // The id the native side wants is the one that identifies the thread
        // on this system: the mach id on macOS, the lwp id elsewhere.
        long[] data = debugger.getThreadIntegerRegisterSet(isDarwin() ? unique_thread_id : thread_id);
        ThreadContext context = BsdThreadContextFactory.createThreadContext(debugger);
        for (int i = 0; i < data.length; i++) {
            context.setRegister(i, data[i]);
        }
        return context;
    }

    public boolean canSetContext() throws DebuggerException {
        return false;
    }

    public void setContext(ThreadContext context)
      throws IllegalThreadStateException, DebuggerException {
        throw new DebuggerException("Unimplemented");
    }

    /** this is not interface function, used in core file to get unique thread id on Macosx*/
    public long getUniqueThreadId() {
        return unique_thread_id;
    }
}
