---
layout: post
title: Clojure AOT via Java Annotation Processor
categories: [blog]
tags: [builds, java, clojure]
---

This post looks at a way to trigger Clojure AOT from a Java Annotation Processor running at Compilation time.

Example code is at <https://github.com/markdingram/blog_clojure_aot>

What is AOT?
============ 

Most commonly Clojure source files are interpreted at runtime. Clojure [Ahead of Time (AOT) Compilation](https://clojure.org/reference/compilation) allows this to happen at compile time, outputting Java class files from the Clojure sources. 

A few reasons are given on the Clojure website, but the main purpose I've come across is for Java interop, generating named classes for use by Java. For example AWS Lambda will require a class that implements `com.amazonaws.services.lambda.runtime.RequestStreamHandler` included in the Lambda ZIP.

> If the long Clojure startup times are an issue for your use case consider using the excellent [Babashka](https://github.com/borkdude/babashka) instead of core Clojure.


What are Java Annotation Processors?
====================================

From [Wikipedia](https://en.wikipedia.org/wiki/Java_annotation) - When Java source code is compiled, annotations can be processed by compiler plug-ins called annotation processors. Processors can produce informational messages or create additional Java source files or resources, which in turn may be compiled and processed.

A couple of examples:

- [Dagger](https://dagger.dev/) - an IoC framework. By pushing the IoC graph materialisation to compile time avoids any runtime pain of trying to debug/understand annotations in any moderately complicated Spring application. Another advantage is there is a nice exit strategy built in - run Dagger one last time and check in the generated source code.

- Similar approach seen in [Micronaut](https://docs.micronaut.io/latest/guide/index.html#ioc)



Example
=======

Example code is at <https://github.com/markdingram/blog_clojure_aot>



Instructions:

````
$ mvn clean package
$ java -jar sample/target/sample-1.0-SNAPSHOT.jar markdingram.sample
Hello AOT!
````


The Aot annotation is added to Java package-info files:


````
@Aot
package markdingram.sample;

import com.github.markdingram.aot.Aot;
````

Upon detection of such an annotation the compilation is triggered using Clojure's Java API:

````
...
IFn compileFn = Clojure.var("clojure.core", "compile");

Var.pushThreadBindings(RT.map(
        Compiler.COMPILE_PATH, outputPath.toString(),
        Compiler.COMPILE_FILES, Boolean.TRUE));
compileFn.invoke(Symbol.create(namespace));
...
````
