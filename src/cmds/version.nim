import os
import strutils

import ../logger
import ../version

proc version() =
    echo "version: ", GdVerStr
    echo "sha:     ", GdGitSha
    echo "author:  ", GdAuthor
    echo "url:     ", GdUrl


proc doVersion *[T](opts: T): int {.discardable.} =
    version()

