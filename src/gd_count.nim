# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
import argparse
import os
import logger

import init

import cmds/count
import cmds/version

when isMainModule:
  import cligen
  include cligen/mergeCfgEnv
  clcfg.version = versionStr()
  init()
  dispatch(countCli, help = {"format": "set format (bel,tsv,twitter,bmtx,mtx,delimited,unknown)",
  "debug": "print debug messages",
  "verbose": "print verbose messages",
  })
