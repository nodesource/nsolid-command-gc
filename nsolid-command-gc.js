#!/usr/bin/env node

'use strict'

// -----------------------------------------------------------------------------
// This is a custom command for N|Solid.  The custom command will trigger
// a garbage collection when invoked.
//
// To enable it in the application you're running, add the following arguments
// to your `nsolid` invocation:
//
//    nsolid --require nsolid-command-gc --expose-gc ...
//
// To invoke the custom command, to request a full GC, use:
//    nsolid-cli custom --id <agentID> --name gc
//
// To to request a minor GC, use:
//    nsolid-cli custom --id <agentID> --name gc --data minor
//
// -----------------------------------------------------------------------------

const path = require('path')

const ModuleName = path.basename(__filename).replace(/\.js$/, '')
const RequestGC = global.gc

// main code just installs the custom command handler
installCommandHandler()

function installCommandHandler () {
  // get the built-in nsolid package, if available
  let nsolid
  try {
    nsolid = require('nsolid')
  } catch (err) {
    emitWarning('not running with nsolid, so not installing gc custom command')
    return
  }

  // make sure there's a gc function
  if (typeof RequestGC !== 'function') {
    emitWarning('global.gc is not a function, so not installing gc custom command')
    emitWarning('did you forget to use node option "--expose-gc"?')
    return
  }

  // register the custom command
  emitWarning('installing nsolid custom command "gc"')
  nsolid.on('gc', gcHandler)
}

// handle the `nsolid custom gc` command
function gcHandler (request) {
  // do a full GC unless minor requested
  const typeGC = (request.value === 'minor') ? 'minor' : 'full'

  emitWarning(`requesting ${typeGC} garbage collection`)
  RequestGC(typeGC === 'full')

  // return normalized parameter ...
  request.return({
    status: 'OK',
    type: typeGC
  })
}

// log a message
function emitWarning (message) {
  if (process.emitWarning) {
    process.emitWarning(message, ModuleName)
  } else {
    console.error(`${ModuleName}: ${message}`)
  }
}
