import logging

var consoleLog = newConsoleLogger()

addHandler(consoleLog)

proc setLevel *(lvl: Level): int {.discardable.} =
    consoleLog.levelThreshold = lvl

export logging