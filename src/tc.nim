import argparse
import os
import logger

import cmds/tc

var p = newParser("tc"):
  flag("--debug")
  flag("--verbose")
  option("-f", "--filter", default = "none", choices = @["lower", "upper", "none"])
  arg("input")
  run:
    setLevel(lvlInfo)
    if opts.debug:
      setLevel(lvlDebug)
    if opts.verbose:
      setLevel(lvlAll)
    doTc(opts)


when isMainModule:
  try:
    p.run()
  except UsageError:
    let msg = getCurrentExceptionMsg()
    echo msg
    echo p.help
    quit(2)

