import os
import strutils
import strformat

import ../logger
import ../version

proc versionStr*(): string =
    &"version: {GdVerStr}" &
    &"\nsha:     {GdGitSha}" &
    &"\nauthor:  {GdAuthor}" &
    &"\nurl:     {GdUrl}"

proc version*() =
    echo versionStr()


proc doVersion *[T](opts: T): int {.discardable.} =
    version()

