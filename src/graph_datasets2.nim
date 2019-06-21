# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
import argparse
import os

import convert


var p = newParser("Some Program"):
  command("dostuff"):
    run:
      echo "Actually do stuff"
  command("convert"):
    arg("input")
    arg("output")
    run:
      convert(opts.input, opts.output)

when isMainModule:

  p.run(commandLineParams())

