# Package

version       = "0.6.0"
author        = "Carl Pearson"
description   = "A dataset manager"
license       = "MIT"
srcDir        = "src"
bin           = @["graph_datasets", "tc"]


# Dependencies

requires "nim >= 0.20.0"
requires "argparse >= 0.9.0"
requires "zip"
requires "untar"
requires "tempdir >= 1.0.0"
requires "https://github.com/brentp/nim-plotly#6ee4fe9fb900565f2ff2155b73983e18fbf0e3ce"
