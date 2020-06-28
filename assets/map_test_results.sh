#!/bin/sh

FILTER='select(."id" | objects | has("testResult")) |
        {label: ."id"[].label,
         id: ."id"[].configuration.id,
         testDurationMillis: .testResult.testAttemptDurationMillis | tonumber,
         testResultStatus: .testResult.status,
         timestamp: (.testResult.testAttemptStartMillisEpoch | tonumber / 1000) | todate }'

tail -f /var/log/bazel/build_events.json 2> /dev/null \
  | jq --unbuffered -c "${FILTER}" \
  | tee /var/log/bazel/test_events.json

