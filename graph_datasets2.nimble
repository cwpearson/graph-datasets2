# Package

version       = "0.2.0"
author        = "Carl Pearson"
description   = "A dataset manager"
license       = "MIT"
srcDir        = "src"
bin           = @["graph_datasets", "tc"]


# Dependencies

requires "nim >= 0.20.0"
requires "argparse"
requires "zip"
requires "untar"
