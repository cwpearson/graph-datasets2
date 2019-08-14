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
import cmds/orient
import cmds/relabel
import cmds/sort
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
    arg("dataset", help = "name of dataset to download")
    flag("--dry-run")
    flag("--force")
    option("--format")
    flag("--list", help = "only list results")
    option("--name")
    option("output", help = "output directory", default = ".")
    option("--provider")
    run:
      doDownload(opts)
  command("orient"):
    arg("input")
    arg("output")
    option("-k", "--kind", default = "upper", choices = @["lower", "upper", "degree"])
    run:
      doOrient(opts)
  command("sort"):
    arg("input")
    arg("output")
    flag("--force")
    run:
      doSort(opts)
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

