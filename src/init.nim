type InitFunc = proc()

var beforeInits: seq[InitFunc]
var inits: seq[InitFunc]
var afterInits: seq[InitFunc]

var init_done = false

proc beforeInit*(f: InitFunc) =
    beforeInits.add(f)

proc atInit*(f: InitFunc) =
    inits.add(f)

proc afterInit*(f: InitFunc) =
    afterInits.add(f)

proc init*() =
    if not init_done:
        for f in beforeInits:
            f()
        for f in inits:
            f()
        for f in afterInits:
            f()
    init_done = true
