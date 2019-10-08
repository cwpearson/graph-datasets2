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
import cmds/generate
import cmds/histogram
import cmds/orient
import cmds/relabel
import cmds/sort
import cmds/version
import cmds/visualize

import format

var p = newParser("graph_datasets"):
  flag("--debug")
  flag("--verbose")
  run:
    setLevel(lvlNotice)
    if opts.debug:
      setLevel(lvlInfo)
    if opts.verbose:
      setLevel(lvlAll)
  command("cacherows"):
    arg("input")
    run:
      doCacherows(opts)
  command("convert"):
    flag("-f", "--force", help = "overwrite output file")
    option("--input-kind", help = "format of input", default = $dkUnknown,
        choices = @[$dkUnknown, $dkBmtx, $dkMtx, $dkTsv, $dkBel, $dkDelimited])
    option("--delimiter", help = "delimiter for rows")
    option("--src-pos", help = "column index for src")
    option("--dst-pos", help = "column index for dst")
    option("--weight-pos", help = "column index for weight")
    arg("input")
    arg("output")
    run:
      doConvert(opts)
  command("count"):
    arg("input")
    option("--format", choices = @["bel", "tsv", "bmtx", "mtx"])
    run:
      doCount(opts)
  command("download"):
    arg("dataset", default = ".*", help = "regex for datasets to download")
    flag("--dry-run")
    flag("--force", help = "overwrite output file")
    option("--format")
    flag("--list", help = "only list results")
    option("--name")
    option("--output", help = "output directory", default = ".")
    option("--provider")
    run:
      doDownload(opts)
  command("generate"):
    arg("output")
    arg("verts")
    arg("edges")
    arg("g")
    flag("--force")
    run:
      doGenerate(opts)
  command("histogram"):
    arg("input")
    option("--output", help = "save output file")
    option("--title", help = "title of histogram",
        default = "Degree Distribution")
    option("--width", help = "width of histogram in px", default = "0")
    option("--height", help = "height of histogram in px", default = "0")
    run:
      doHistogram(opts)
  command("orient"):
    arg("input")
    arg("output")
    option("-k", "--kind", default = "upper", choices = @["lower", "upper", "degree"])
    run:
      doOrient(opts)
  command("sort"):
    arg("input")
    arg("output")
    option("-k", "--kind", default = "src", choices = @["src", "dst"])
    flag("-f", "--force", help = "overwrite output file")
    run:
      doSort(opts)
  command("relabel"):
    arg("input")
    arg("output")
    flag("-f", "--force", help = "overwrite output file")
    option("-k", "--kind", default = "random", choices = @["random", "compact"],
        help = "relabel method")
    option("--seed", default = "0")
    run:
      doRelabel(opts)
  command("version"):
    run:
      doVersion(opts)
  command("visualize"):
    arg("input")
    arg("output")
    flag("--no-log", help = "do not apply log scaling")
    option("--img-width", default = "0")
    option("--img-height", default = "0")
    option("--mat-width", default = "0")
    option("--mat-height", default = "0")
    option("--size", help = "image size", default = "1000")
    run:
      doVisualize(opts)


when isMainModule:
  init()
  try:
    p.run()
  except UsageError:
    let msg = getCurrentExceptionMsg()
    echo msg
    echo p.help
    quit(2)

