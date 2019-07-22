import logging

var consoleLog = newConsoleLogger(useStdErr = true)

addHandler(consoleLog)

proc setLevel *(lvl: Level) =
    consoleLog.levelThreshold = lvl

template debug*(args: varargs[string, `$`]) =
    while not defined(release):
        log(lvlDebug, args)

template info*(args: varargs[string, `$`]) =
    logging.info(args)

template notice*(args: varargs[string, `$`]) =
    logging.notice(args)

template warn*(args: varargs[string, `$`]) =
    logging.warn(args)

template error*(args: varargs[string, `$`]) =
    logging.error(args)

export Level
