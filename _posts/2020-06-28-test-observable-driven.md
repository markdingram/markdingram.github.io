---
layout: post
title: Test Run Observability
categories: [blog]
tags: [builds, honeycomb, bazel]
---


I've been witness to a few monorepo projects where Pull Requests to main are blocked until after a successful 
CI pipeline run. In each case the CI pipelines have largely been a blackbox neglected until.. suddenly 
a sufficient threshold of pain across the organisation is breached. My tolerance seems lower than most as all
I can see are the sands of productivity draining away from the organisation well before the immediate threshold!
 


 

Why not put in observability at the earliest possible time? 



This post gives of an overview of a simple feed of test runs from Bazel into [Honeycomb](honeycomb.io) via 
Bazel's [Build Event Protocol](https://docs.bazel.build/versions/master/build-event-protocol.html) (BEP)
 and Honeycomb's [Honeytail](https://docs.honeycomb.io/getting-data-in/integrations/honeytail/) agent.
 
 
Step 1 - Output test run from Bazel
===================================
 
Add a flag to `.bazelrc` to produce an [NDJSON](http://ndjson.org/) file containing various build events:

````
common --build_event_json_file="/var/log/bazel/build_events.ndjson"
````

> There is also an `bes_backend` option to send the data via GRPC. Could be interesting to 
> see if a Lambda could receive via this route for serverless handling.
 
For this exercise the data from the BES `testResult` events will be sent through to Honeycomb:
 
````
$ bazel test //feed/...
...
Executed 1 out of 1 test: 1 fails locally.
INFO: Build Event Protocol files produced successfully.
INFO: Build completed, 1 test FAILED, 2 total actions
````
 
````
 {
   "id": {
     "testResult": {
       "label": "//feed/src/test/clj/clj_stomp/alpha:alpha",
       "run": 1,
       "shard": 1,
       "attempt": 1,
       "configuration": {
         "id": "9d0af820af00b297c2128aed3f4a3f642a7a422457413b1c89acc467b7badc18"
       }
     }
   },
   "testResult": {
     ...
     "testAttemptDurationMillis": "46",
     "status": "FAILED",
     "testAttemptStartMillisEpoch": "1593379441817",
     ...
   }
 }
````
 
Formatting the Bazel event
==========================

Honeycomb maybe able to consume the events directly - but I didn't check. Instead JQ is used to flatten and reduce 
the output event into a simplified format:

 ![map_test_results.sh](/assets/map_test_results.sh)

````
{"label":"//feed/src/test/clj/clj_stomp/alpha:alpha","id":"9d0af820af00b297c2128aed3f4a3f642a7a422457413b1c89acc467b7badc18","testDurationMillis":46,"testResultStatus":"FAILED","timestamp":"2020-06-28T21:21:17Z"}
````

> <https://jqplay.org> was invaluable here
 
 
 
Honeycomb
=========

Signing up to Honeycomb and installing the [Honeytail agent](https://docs.honeycomb.io/getting-data-in/integrations/honeytail/) is very straightforward.  
 
Once the agent is installed edit `/etc/honeytail/honeytail.conf`:

````
ParserName = json
WriteKey = XXXX
LogFiles = /var/log/bazel/test_events.json
Dataset = bazel
````

Start the agent & begin running Bazel tests - all being well the data will soon be flowing into the Honeycomb UI ready for analysis!

 ![honeycomb.png](/assets/honeycomb.png)


Summary
=======

This post showed how to get started with test run outcomes into Honeycomb in a low tech manner. Even this minimal setup
could provide the necessary observability into test pipelines to detect and take action prior to a blowout!


A couple of links to checkout - 
<https://www.heavybit.com/library/podcasts/o11ycast/ep-21-learning-systems-with-jessica-kerr>

<https://thenewstack.io/a-next-step-beyond-test-driven-development>