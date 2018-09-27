---
layout: post
title: Single build to call Haskell from Java
categories: [blog]
tags: [builds, java, haskell, nix, bazel]
---

One of the promises of [Bazel](https://bazel.build/) is "One tool, multiple languages". Let's validate this claim - but which languages to choose? 

I've recently been learning Haskell and came across this [post](https://www.tweag.io/posts/2018-02-28-bazel-haskell.html) with Bazel rules for Haskell, and then saw there were also [JNI bindings](https://github.com/tweag/inline-java/tree/master/jni) setup with a Bazel build. So the goal is a single build that creates a Java application that calls through JNI into Haskell.

> NOTE: It became apparent that getting an OSX build working in tandom wouldn't be straightforward. As per https://github.com/tweag/inline-java/issues/1 switching to the cpphs preprocessor is needed, however I then encountered a problem where the MIN_VERSION_singletons macro is not supplied, contrary to what was expected from a similar [issue](https://github.com/glaebhoerl/type-eq/issues/3). A workaround would be to fork upstream and remove the macros to only support latest version.
