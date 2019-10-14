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

proc doVersion *[T](opts: T): int {.discardable.} =
    echo versionStr()

