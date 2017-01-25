#!/usr/bin/env bash

jq --version > /dev/null
if [ $? -ne 0 ]; then
  echo "this script requires the jq command: https://stedolan.github.io/jq/"
  exit 1
fi

nsolid-cli --v > /dev/null
if [ $? -ne 0 ]; then
  echo "this script requires the nsolid-cli command to be available"
  exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
TEST_DIR="${SCRIPT_DIR}/tmp/test-in-tmp"

echo "running test in $TEST_DIR"

# create (if needed) and cd into test directory
mkdir -p "${TEST_DIR}"
cd "${TEST_DIR}"

# add package.json (for npm install, next) if doesn't exist
if [ ! -f package.json ]; then
  DEFAULT_PACKAGE_JSON=
  echo '{"name": "test-in-tmp"}' > package.json
fi

# install this package
echo ""
echo "running 'npm install' this package"
npm install ../..

# start up the garbage generator
export NSOLID_APPNAME=generate-garbage-tester
export NSOLID_COMMAND=9001
export NSOLID_ENABLE_GC="--require nsolid-command-gc --expose-gc"

echo ""
echo "starting garbage generator in the background"
nsolid $NSOLID_ENABLE_GC ../../test/generate-garbage.js &
TEST_APP_PID=$!

AGENT_ID=`nsolid-cli ls | grep $NSOLID_APPNAME | head -n 1 | jq --raw-output .id`

echo ""
echo "test app PID: $TEST_APP_PID"
echo "agent id:     $AGENT_ID"

echo ""
echo "invoking the custom command"
echo ""

ERRORS=0

# test minor GC

RESULT=`nsolid-cli custom --id $AGENT_ID --name gc --data minor | jq --raw-output .result.status`
if [[ "$RESULT" != "OK" ]]; then
  (( ERRORS += 1 ))
  echo "ERROR: test expected OK status from minor GC, but got $RESULT"
fi

RESULT=`nsolid-cli custom --id $AGENT_ID --name gc --data minor | jq --raw-output .result.type`
if [[ "$RESULT" != "minor" ]]; then
  (( ERRORS += 1 ))
  echo "ERROR: test expected minor type from minor GC, but got $RESULT"
fi

# test full GC when using no value parameter

RESULT=`nsolid-cli custom --id $AGENT_ID --name gc | jq --raw-output .result.status`
if [[ "$RESULT" != "OK" ]]; then
  (( ERRORS += 1 ))
  echo "ERROR: test expected OK status from full GC, but got $RESULT"
fi

RESULT=`nsolid-cli custom --id $AGENT_ID --name gc | jq --raw-output .result.type`
if [[ "$RESULT" != "full" ]]; then
  (( ERRORS += 1 ))
  echo "ERROR: test expected full type from full GC, but got $RESULT"
fi

# test full GC when using value parameter 'full'

RESULT=`nsolid-cli custom --id $AGENT_ID --name gc --value full | jq --raw-output .result.status`
if [[ "$RESULT" != "OK" ]]; then
  (( ERRORS += 1 ))
  echo "ERROR: test expected OK status from full GC with value parameter, but got $RESULT"
fi

RESULT=`nsolid-cli custom --id $AGENT_ID --name gc --value full | jq --raw-output .result.type`
if [[ "$RESULT" != "full" ]]; then
  (( ERRORS += 1 ))
  echo "ERROR: test expected full type from full GC with value parameter, but got $RESULT"
fi

# test with junk value parameter

RESULT=`nsolid-cli custom --id $AGENT_ID --name gc --value junk | jq --raw-output .result.status`
if [[ "$RESULT" != "OK" ]]; then
  (( ERRORS += 1 ))
  echo "ERROR: test expected OK status from full GC with junk value parameter, but got $RESULT"
fi

RESULT=`nsolid-cli custom --id $AGENT_ID --name gc --value junk | jq --raw-output .result.type`
if [[ "$RESULT" != "full" ]]; then
  (( ERRORS += 1 ))
  echo "ERROR: test expected full type from full GC with junk value parameter, but got $RESULT"
fi

# kill the garbage generator
kill $TEST_APP_PID

if [ $ERRORS -eq 0 ]; then
  echo ""
  echo "All tests passed!"
else
  echo ""
  echo "ERRORs found when running tests: $ERRORS"
  exit 1
fi
