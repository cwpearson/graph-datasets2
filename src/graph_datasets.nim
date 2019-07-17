# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
import argparse
import os
import logger

import cmds/convert
import cmds/count
import cmds/orient
import cmds/relabel

var p = newParser("Some Program"):
  flag("--debug")
  flag("--verbose")
  run:
    setLevel(lvlInfo)
    if opts.debug:
      setLevel(lvlDebug)
    if opts.verbose:
      setLevel(lvlAll)
  command("convert"):
    arg("input")
    arg("output")
    run:
      doConvert(opts)
  command("count"):
    arg("input")
    run:
      doCount(opts)
  command("orient"):
    arg("input")
    arg("output")
    option("-k", "--kind", default="upper", choices = @["lower", "upper", "degree"])
    run:
      doOrient(opts)
  command("relabel"):
    arg("input")
    arg("output")
    run:
      doRelabel(opts)


when isMainModule:
  p.run()

