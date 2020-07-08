---
layout: post
title: Basic CDK deployment pipeline with GitHub Actions
categories: [blog]
tags: [ci, bazel, cdk, deployment]
---


Introduction
============

At the time of writing [Github Actions](https://github.com/pricing) has a free tier allowing 2,000 minutes a month of builds for private repos. For smaller / side projects that are already hosted on GitHub it is straightforward to setup a PR based workflow to automate the deployment process.

A CI/CD process suitable for a small project could be:

- PR workflow:
	- on every pull request commit targeting main branch:
	    - run all tests
		- run `cdk synth` and to produce a Cloud Assembly directory (cdk.out) with the latest changes
		- run `cdk diff` with the produced Cloud Assembly
		- post diff as a comment to the PR

- Main workflow:
	- on every commit to main branch:
	    - acquire cdk.out artifact from the PR workflow synth
		- run `cdk apply` with that Cloud Assembly


Currently Github actions don't make it too easy to share artifacts between different workflows (see <https://github.com/actions/download-artifact/issues/3>). It is now possible via wrangling the APIs but until it gets polished we'll amend the main workflow as follows:

- Main workflow:
	- on every commit to main branch:
		- *run `cdk synth` and to produce a Cloud Assembly directory (cdk.out) with the latest changes*
		- run `cdk apply` with the produced Cloud Assembly



PR Workflow
===========

Using the same repo as [previously](./2020-06-30-bazel-clojure.md) introduced <https://github.com/markdingram/bazel-cdk-clojure>, a [pr.yml workflow](https://github.com/markdingram/bazel-cdk-clojure/blob/fc3d5b4259fe825e945227e70a6aa98f0fdbdd40/.github/workflows/pr.yml) is added.

> Aside: I lost count of the number of broken links I saw from not using permanent Github links - to get a permalink simply press `y`

While the generation of the cdk.out directory uses Bazel, the diff / apply of that product is done without reference to Bazel using an NPM installed CDK binary. Simplifying down this example for a pure NPM Javascript project would be straightforward.

The workflow shouldn't be complicated to follow, in the `build` job the steps of interest are:

````
- name: Test
  run: |
    bazel test //...

- name: Synth
  run: |
    bazel build infra:synth
    find dist/bin/infra/cdk.out -type d -exec chmod 0755 {} \;

- name: Upload Cloud Assembly
  uses: actions/upload-artifact@v1
  with:
    name: cdk.out
    path: dist/bin/infra/cdk.out
````

As required run all tests first. A Bazel synth rule has been added to output the Cloud Assembly `dist/bin/infra/cdk.out` via `bazel build infra:synth`. 

As of now CDK likes to add '.cache' directories inside the cdk.out directory when uploading assets to S3. Given all Bazel output is read only make the directories writable prior to uploading as an artifact.

In the `diff` job the steps of note are:

````
- name: Download Cloud Assembly
  uses: actions/download-artifact@v1
  with:
    name: cdk.out

- name: Run CDK diff
  run: node_modules/.bin/cdk diff -c aws-cdk:enableDiffNoFail=true --no-color --app cdk.out "*" 2>&1 | tee cdk.log

- name: Add comment to PR
  env:
    URL: ${{ github.event.pull_request.comments_url }}
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    jq --raw-input --slurp '{body: .}' cdk.log > cdk.json
    curl \
      -H "Content-Type: application/json" \
      -H "Authorization: token $GITHUB_TOKEN" \
      -d @cdk.json \
      -X POST \
      $URL
````


JQ is used to slurp the raw text output of CDK diff into a JSON message suitable for uploading to Github. Presumably there is a Github action that would encapsulate the PR comment posting, but the Rest API is so straightforward adding a dependency for that seems overkill.

With this workflow in place a CDK diff should spring onto the PR after a few minutes:

 ![cdk_diff.png](/assets/cdk_diff_pr.png)


It is also useful to setup a Github Branch protection rule that ensures the PR workflow is successful prior to merge:

 ![gh_branch_protection.png](/assets/gh_branch_protection.png)


The main workflow is similar to the PR one, but with a `cdk deploy` step instead.


Notes
=====

* I first encountered showing planned changes on Pull Requests from [Atlantis](https://www.runatlantis.io) a couple of years ago. I believe Hashicorp hired the maintainer from that to work on [Terraform cloud](https://www.terraform.io/docs/cloud/index.html), so worth checking both of these for inspiration! 

* The Amazon equivalent [AWS CodeBuild](https://aws.amazon.com/codebuild/pricing) free tier is only a miserly 100 minutes. After the free tiers run out the AWS lowest tier of build instances (general1.small) is cheaper than GitHub ($0.005/minute for a general1.small vs $0.008), but has less RAM (3GB compared to 7GB). For larger projects I'd be inclined to pursue AWS (configured via CDK of course!). The CodeBuild / CodePipeline constructs & further integration over time with CDK / CloudFormation will likely allow more detailed/involved workflows to be constructed.
