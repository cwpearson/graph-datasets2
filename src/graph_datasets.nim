# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
import argparse
import os
import logger

import init
import cmds/cacherows
import cmds/convert
import cmds/count
import cmds/download
import cmds/list
import cmds/orient
import cmds/relabel
import cmds/version

var p = newParser("graph_datasets"):
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
    flag("--force")
    arg("input")
    arg("output")
    run:
      doConvert(opts)
  command("count"):
    arg("input")
    run:
      doCount(opts)
  command("download"):
    flag("--force")
    flag("--dry-run")
    option("output", help = "output directory", default = ".")
    arg("dataset", help = "name of dataset to download")
    run:
      doDownload(opts)
  command("list"):
    flag("--full")
    option("--name")
    option("--provider")
    option("--format")

    run:
      doList(opts)
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
  init()
  try:
    p.run()
  except UsageError:
    let msg = getCurrentExceptionMsg()
    echo msg
    echo p.help
    quit(2)

