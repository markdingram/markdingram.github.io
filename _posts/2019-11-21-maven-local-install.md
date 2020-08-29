---
title: Maven Local Install
categories: [blog]
tags: [builds, java, maven]
---

Very occasionally the need arises to push a 3rd party JAR that isn't publically hosted on Maven into a private repo hosted on S3. The trick is to get Maven to produce the necessary metadata files rather than editing by hand.

Here's an example with the Amazon 'in-app-purchasing-2.0.76.jar' downloadable from <https://developer.amazon.com/apps-and-games/sdk-download>, but not published to any of the usual Maven public repos.

````
$ curl -O https://amazonadsi-a.akamaihd.net/public/Amazon-Mobile-App-SDK-by-Platform/Amazon-Android-SDKs.zip
$ unzip Amazon-Android-SKDs.zip
$ mkdir local-maven-repo
$ mvn deploy:deploy-file -DgroupId=com.amazon -DartifactId=in-app-purchasing -Dversion=2.0.76 -Durl=file:./local-maven-repo -DrepositoryId=local-maven-repo -DupdateReleaseInfo=true -Dfile=Amazon-Android-SDKs/AmazonInAppPurchasing/in-app-purchasing-2.0.76.jar
INFO] Scanning for projects...
[INFO]
[INFO] ------------------< org.apache.maven:standalone-pom >-------------------
[INFO] Building Maven Stub Project (No POM) 1
[INFO] --------------------------------[ pom ]---------------------------------
[INFO]
[INFO] --- maven-deploy-plugin:2.7:deploy-file (default-cli) @ standalone-pom ---
Uploading to local-maven-repo: file:./local-maven-repo/com/amazon/in-app-purchasing/2.0.76/in-app-purchasing-2.0.76.jar
Uploaded to local-maven-repo: file:./local-maven-repo/com/amazon/in-app-purchasing/2.0.76/in-app-purchasing-2.0.76.jar (100 kB at 1.8 MB/s)
Uploading to local-maven-repo: file:./local-maven-repo/com/amazon/in-app-purchasing/2.0.76/in-app-purchasing-2.0.76.pom
Uploaded to local-maven-repo: file:./local-maven-repo/com/amazon/in-app-purchasing/2.0.76/in-app-purchasing-2.0.76.pom (401 B at 134 kB/s)
Downloading from local-maven-repo: file:./local-maven-repo/com/amazon/in-app-purchasing/maven-metadata.xml
Uploading to local-maven-repo: file:./local-maven-repo/com/amazon/in-app-purchasing/maven-metadata.xml
Uploaded to local-maven-repo: file:./local-maven-repo/com/amazon/in-app-purchasing/maven-metadata.xml (309 B at 103 kB/s)
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.116 s
[INFO] Finished at: 2019-11-21T10:19:34Z
[INFO] ------------------------------------------------------------------------
$ tree local-maven-repo
local-maven-repo
└── com
    └── amazon
        └── in-app-purchasing
            ├── 2.0.76
            │   ├── in-app-purchasing-2.0.76.jar
            │   ├── in-app-purchasing-2.0.76.jar.md5
            │   ├── in-app-purchasing-2.0.76.jar.sha1
            │   ├── in-app-purchasing-2.0.76.pom
            │   ├── in-app-purchasing-2.0.76.pom.md5
            │   └── in-app-purchasing-2.0.76.pom.sha1
            ├── maven-metadata.xml
            ├── maven-metadata.xml.md5
````

The local-maven-repo can then be synced across to an S3 bucket and used as a Maven repo, for example:

<https://github.com/s3-wagon-private/s3-wagon-private>

<https://tech.asimio.net/2018/06/27/Using-an-AWS-S3-Bucket-as-your-Maven-Repository.html>

