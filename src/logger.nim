import logging

var consoleLog = newConsoleLogger(useStdErr = true)

addHandler(consoleLog)

proc setLevel *(lvl: Level): int {.discardable.} =
    consoleLog.levelThreshold = lvl

export logging