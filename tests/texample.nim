import unittest

import logger, init

suite "test logger":
    init()
    test "debug":
        setLevel(lvlDebug)
        debug("this is a debug message")
    test "warn":
        setLevel(lvlWarn)
        warn("this is a warning message")


