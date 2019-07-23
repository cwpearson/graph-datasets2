import os

import ../logger
import ../version

proc version() =
    echo paramStr(0)
    echo "version: ", GdVerStr
    echo "sha:     ", GdGitSha


proc doVersion *[T](opts: T): int {.discardable.} =
    version()

