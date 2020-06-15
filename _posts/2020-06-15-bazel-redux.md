---
layout: post
title: Bazel Redux
categories: [blog]
tags: [builds, java, haskell, nix, bazel]
---

A lot changed in the Bazel ecosystem since the previous 2018 post. I brought the [repo](http://github.com/markdingram/java-jni-haskell) up to date with latest Bazel (3.3.0) & Haskell rules.


Notes:

- The .bazelversion file now specifies the exact Bazel version that was last used, to encourage reproducability - similar to the jenv (Java) / nvm (Node).

- The WORKSPACE now sets up the @openjdk / @stackage repositories referenced by the JNI dependency: <https://github.com/tweag/inline-java/blob/ab4b05aa423ef04951ff9a06275b48e662f139e0/jni/BUILD.bazel>.  

- Got stuck for a while on `fatal error: jni.h: No such file or directory` from the line `#include <jni.h>` in the JNI project. A comment on [Stack Overflow](https://stackoverflow.com/questions/51427219/c-bazel-how-to-include-angle-bracket-system-headers/51441444#comment110318539_51441444) pointed to the solution - `strip_include_prefix = "."`. This changes the `-I` paths sent to the compiler, allowing the bracketed (system) header import to succeed.

- `/usr/bin/ld.gold: error: external/rules_haskell_ghc_linux_amd64/lib/rts/libHSrts.a(CNF.o): requires unsupported dynamic reloc 11; recompile with -fPIC` - resolved by switching the cc_binary to `linkstatic = False`. At a guess the Haskell libraries from stackage aren't suitable for dynamic reloc (yet?). This could be worked around by building all the libraries ourselves with the necessary flags. 
