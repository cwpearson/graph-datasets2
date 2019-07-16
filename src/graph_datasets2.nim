# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
import argparse
import os
import logger

import convert
import count
import orient
import relabel



var p = newParser("Some Program"):
  flag("--debug")
  flag("--verbose")
  command("dostuff"):
    run:
      echo "Actually do stuff"
  command("convert"):
    arg("input")
    arg("output")
    run:
      convert(opts.input, opts.output)
  command("count"):
    arg("input")
    run:
      count(opts.input)
  command("orient"):
    arg("input")
    arg("output")
    option("-k", "--kind", default="upper", choices = @["lower", "upper", "degree"])
    run:
      var kind: Orientation
      case opts.kind
      of "lower":
        kind = oLowerTriangular
      of "upper":
        kind = oUpperTriangular
      of "degree":
        kind = oDegree
      else:
        quit(1)
      orient(opts.input, opts.output, kind)
  command("relabel"):
    arg("input")
    arg("output")
    run:
      orient(opts.input, opts.output)

when isMainModule:
  let opts = p.parse(commandLineParams())
  setLevel(lvlInfo)
  if opts.debug:
    setLevel(lvlDebug)
  if opts.verbose:
    setLevel(lvlAll)
  p.run(commandLineParams())

