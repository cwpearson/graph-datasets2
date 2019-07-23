# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
import argparse
import os
import logger
import logging

import cmds/cacherows
import cmds/convert
import cmds/count
import cmds/download
import cmds/orient
import cmds/relabel
import cmds/version

var p = newParser("grpah_datasets"):
  flag("--debug")
  flag("--verbose")
  run:
    setLevel(lvlInfo)
    if opts.debug:
      setLevel(lvlDebug)
    if opts.verbose:
      setLevel(lvlAll)
  command("cacherows"):
    arg("input")
    run:
      doCacherows(opts)
  command("convert"):
    arg("input")
    arg("output")
    run:
      doConvert(opts)
  command("count"):
    arg("input")
    run:
      doCount(opts)
  command("download"):
    arg("name")
    run:
      doDownload(opts)
  command("orient"):
    arg("input")
    arg("output")
    option("-k", "--kind", default = "upper", choices = @["lower", "upper", "degree"])
    run:
      doOrient(opts)
  command("relabel"):
    arg("input")
    arg("output")
    run:
      doRelabel(opts)
  command("version"):
    run:
      doVersion(opts)


when isMainModule:
  try:
    p.run()
  except UsageError:
    let msg = getCurrentExceptionMsg()
    echo msg
    echo p.help
    quit(2)

