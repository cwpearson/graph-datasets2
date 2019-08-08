import unittest

import dict

suite "test dict":

    test "init":
        var d = initDict[string, int]()
        check len(d) == 0
    test "rightSize":
        var d = initDict[string, int](rightSize(511))
        check len(d) == 0

    test "hasKeyOrPut":
        var d = initDict[string, int]()
        check d.hasKeyOrPut("hello", 0) == false
        check len(d) == 1
        check d.hasKeyOrPut("hello", 0) == true
        check d["hello"] == 0

    test "getOrDefault":
        var d = initDict[string, int]()
        var default: int
        check d.getOrDefault("hello") == default
        d["hello"] = 1
        check d.getOrDefault("hello") == 1
