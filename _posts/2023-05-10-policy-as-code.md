# Policy as Code (from an internal company newsletter)

## Introduction

Over the past decade, the DevOps community has been advocating for the use of automation and software development practices to manage IT infrastructure and operations - aka Infrastructure as Code - IaC. The concept of "Policy as Code" has more recently emerged as a natural extension of this movement, referencing the use of code to manage organisational policies and/or rules. As shown in the JIRA example below the concept can be applied to any endeavour where the underlying data is readily available.
 
Our co's rapid growth has naturally led to a position where policies have been defined in Confluence pages of differing vintages - which is fine, if mentally taxing & time consuming for both those setting the rules and those attempting to follow. This article will draw, via comparison to the beneficial advances in software development after the adoption of unit testing, a sketch of what organisational benefits could accrue from an adoption of Policy as Code - more efficient, transparent, and consistently applied policies leading to a more nimble, adaptable and capable organisation.

## The Rise of Unit Testing

In the early 2000s unit testing had not quite been universally accepted - this author can just about remember the misfortune of working on more than one project of this era with bugs that would embarrassingly reoccur shortly after being "fixed" due to an unintended regression. These weren't complicated bugs at the intersection of several systems, but plain logic errors. Fortunately it has long since been accepted that production systems should be accompanied by unit tests to independently validate expected behaviour - a well written unit test can be run cheaply and instantly in perpetuity against every proposed change to assert the ongoing software quality.
 
Less commented on, but just as powerful is the benefit of the insane productivity boost from the instant feedback available when developing against a system with good tests - many regressions can be caught long before they ever make it into a git commit, never mind a test environment - a shortening of the so called "inner dev loop".
 
While obvious in retrospect it did take a while for these ideas to percolate through. Is "Policy as a Code" at a similar stage of evolution? Will it provide a similar boost at an organisational level such that we look back in 10 years and wonder how we collectively ever operated without it? Bold claims & perhaps not quite! But it's certainly an area worth exploring.


## Example: Validating a Jira has Story points

A team or organisation may choose to set the policy that all JIRAs that are in flight should have a Story Point estimate. This shell script uses the Jira API to validate this:


````
#!/bin/bash
JIRA_ID=$1
[ -z "$JIRA_USER" ] && { echo "Please set JIRA_USER"; exit 2; }
[ -z "$JIRA_ACCESS_TOKEN" ] && { echo "Please set JIRA_ACCESS_TOKEN"; exit 2; }
[ -z "$JIRA_ID" ] && { echo "Please pass JIRA ID as arg"; exit 2; }
has_story_points () {
   story_points_field="customfield_10004"
   curl -s -u $JIRA_USER:$JIRA_ACCESS_TOKEN "https://xxx.atlassian.net/rest/api/2/issue/$JIRA_ID?fields=$story_points_field" | jq -e ".fields.$story_points_field != null" >/dev/null
}
if has_story_points; then
  echo "$JIRA_ID - OK"
else
  echo "$JIRA_ID - No Story Points"
  exit 1
fi
 ````

In use:


````
❯ ./jira-has-story-points.sh XXX-1
TRCRS-1 - No Story Points
❯ ./jira-has-story-points.sh XXX-2772
TRCRS-2772 - OK
````

This example with “just” Bash + Curl + JQ shows that “Policy as Code” is not tied to any particular language, framework or expensive SaaS product → it is a practice just like Unit Testing & the important thing is to give the machine the opportunity to do the work of policy validation.
 
### Summary

"Policy as Code" is a relatively new spin applying the game changing approach of unit testing to organisational policies. There are many examples  where this approach could be applied - think of all the policies already written in Confluence that can be expressed in data & checked. As shown by the example there is a low barrier to entry - are we ready to begin some cross team collaborations to build “Policy as Code” from ground up? Let’s build small and grow...
