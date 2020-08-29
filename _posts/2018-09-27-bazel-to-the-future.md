---
title: Bazel to the Future
categories: [blog]
tags: [builds, java, haskell, nix, bazel]
---

One of the promises of [Bazel](https://bazel.build/) is "One tool, multiple languages". Let's validate this claim - but which languages to choose? 

I've recently been learning Haskell and came across this [post](https://www.tweag.io/posts/2018-02-28-bazel-haskell.html) by Tweag announcing Bazel rules for Haskell. Another project by Tweag provides Haskell [JNI bindings](https://github.com/tweag/inline-java/tree/master/jni) and is setup with a Bazel build, so the goal is to create a single Bazel build that produces a Java application calling through JNI into Haskell. To keep it simple the Haskell code will calculate a Fibonacci number.

Resulting repo is here: <http://github.com/markdingram/java-jni-haskell>, tested on Fedora.

To run:

````
bazel run //fibhs:main 10
bazel run //fibjava:main 10
...
fib(10) = 89
````


Part 1 - Pure Haskell
=====================

First task was to create a pure Haskell library/application for Fibonacci:

````
fib :: Int -> Int
fib 0 = 1
fib 1 = 1
fib n = fib (n-1) + fib (n-2)
````

This proved to be straightforward, lifting the template from the [rules_haskell_examples](https://github.com/tweag/rules_haskell_examples) repo: 
````
$ bazel run //fibhs:main 10 
...
fib(10) = 89
````

Part 2 - JNI
============

Here the real excitement began. I found this [repository](https://github.com/mhlopko/bazel-jni-example) with an example of a C++ JNI build, so that was the starting point. 

Importing the upstream bazel JNI build was straightforward, following this section in the WORKSPACE

````
git_repository(
    name = "tweag_inline_java",
    remote = "https://github.com/tweag/inline-java.git",
    tag = "v0.8.4")
````

The JNI library can then be referenced as a dependency with `@tweag_inline_java:jni/jni`


Before calling any Haskell methods, the [Haskell FFI](https://downloads.haskell.org/~ghc/8.2.2/docs/html/users_guide/ffi-chap.html#making-a-haskell-library-that-can-be-called-from-foreign-code) requires that the hs_init method (from HsFFI.h) method is called from C prior to any other calls. The standard JNI_OnLoad method in `init.c` is defined to trigger this at library load time.


From this point on I ran into a time consuming series of irritants caused by what seemed to be a combination of my lack of experience with Bazel/Haskell and misleading/incomplete documentation:

* Unable to find the JNI header files in a subdirectory which turned out to be <https://github.com/bazelbuild/bazel/issues/5497>, I'm sure there is a more elegant approach but adding `../` to the includes paths got past it.


* a blind alley triggered by the following paragraph in the Bazel docs for cc_binary, linkstatic:

  _The presence of this flag means that linking occurs with the -shared flag to gcc, and the resulting shared library is suitable for loading into for example a Java program. However, for build purposes it will never be linked into the dependent binary, as it is assumed that shared libraries built with a cc_binary rule are only loaded manually by other programs, so it should not be considered a substitute for the cc_library rule. For sake of scalability we recommend avoiding this approach altogether and simply letting java_library depend on cc_library rules instead._

  Turns out the cc_library doesn't retain the dynamic link to the Haskell runtime (check with ldd), leading to an error when trying to load the library from Java down the line. cc_binary does include that link so stick with that. 

* The non threaded Haskell runtime hangs when loaded from Java, using the Haskell threaded runtime was needed. The approach described here <https://github.com/tweag/rules_haskell/issues/437> was the key.

* Native libraries in `data` are handled differently by Bazel Java library vs binary - see <https://github.com/bazelbuild/bazel/issues/1146>. 

* one self inflicted interlude, while wrestling with the above I spent some time seeing if an OSX build could be added, it soon became apparent this wouldn't be straightforward. As per https://github.com/tweag/inline-java/issues/1 switching to the cpphs preprocessor is needed, however the MIN_VERSION_singletons macro wasn't provided to cpphs leading to build errors. This was contrary to what was expected from a similar [issue](https://github.com/glaebhoerl/type-eq/issues/3) but I didn't investigate any further.

Dependency Graph
================

One nice feature supported by Bazel is producing a dependency graph:

````
$ bazel query  --nohost_deps --noimplicit_deps "deps(//fibjava:main)" --output graph > graph.dot
$ /usr/bin/dot -Tpng graph.dot -o deps.png
````

Resulting graph for this exercise:

![Deps](/assets/deps.png)
  

Conclusion
==========

Bazel has lived up to its claim, a single command can build & run either Haskell or Java/JNI/Haskell binaries.

The support for tagged import of the upstream Git JNI repository shows that Bazel, despite its monorepo origins, may be able to support multirepo approaches too.


Alternate Timeline
==================

[Eta](https://eta-lang.org) with its own [Bazel rules](https://github.com/jin/rules_eta) is an alternate approach, running Haskell direct on the JVM. Maybe for later investigation..
