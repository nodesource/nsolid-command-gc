#!/usr/bin/env node

'use strict'

// amount of garbage to generate every interval
const BufferSize = 100000

// millisecond interval to allocate garbage
const BufferInterval = 1

const path = require('path')

// set the process title to the name of the file
process.title = path.basename(__filename).replace(/\.js$/, '')

console.log('generating garbage to test with nsolid-command-gc')

// set a timer interval to generate garbage
setInterval(generateGarbage, BufferInterval)

// set a timer interval to print stats
setInterval(printStats, 5000)

// some stats to print
let AllocatedAmount = 0
let AllocatedTimes = 0
let AllocatedStart = Date.now()

// this variable holds onto some garbage
let lastValue

// generate some garbage
function generateGarbage () {
  // allocate some garbage
  lastValue = new Buffer(BufferSize)

  // update stats
  AllocatedAmount += lastValue.length
  AllocatedTimes++
}

// print stats
function printStats () {
  const amt = AllocatedAmount.toLocaleString()
  const times = AllocatedTimes.toLocaleString()
  const secs = Math.round((Date.now() - AllocatedStart) / 1000)

  console.log(`allocated ${amt} garbage bytes via ${times} Buffers over ${secs} seconds`)
}
