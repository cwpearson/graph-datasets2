import streams
import system
import strutils
import sequtils
import algorithm
import tables

type Edge = tuple[src: uint64, dst: uint64]

proc convert *(src: string, dst:string): int {.discardable.} = 
    echo "converting ", src, " to ", dst

    var edges: seq[Edge]

    var canonical = initTable[uint64, uint64]()
    var nextId = 0'u64

    echo "opening ", src
    var strm = newFileStream(src, fmRead)
    var line = ""
    if not isNil(strm):
        while strm.readLine(line):
            echo "read ", line
            var fields: seq[string] = line.splitWhitespace()
            var user = parseBiggestUint fields[0]
            var follower = parseBiggestUint fields[1]
            if not canonical.hasKey(user):
                canonical[user] = nextId
                nextId += 1
            if not canonical.hasKey(follower):
                canonical[follower] = nextId
                nextId += 1
            var src = canonical[user]
            var dst = canonical[follower]
            edges.add((src, dst))
            edges.add((dst, src))
    else:
        echo "error opening ", src
        quit(1)
    strm.close()

    # Sorting with custom proc
    echo "sorting..."
    edges.sort do (x, y: Edge) -> int:
        result = cmp(x.dst, y.dst)
        if result == 0:
            result = cmp(x.src, y.src)

    echo "writing ", dst
    strm = newFileStream(dst, fmWrite)
    for e in edges:
        strm.write(e.dst)
        strm.write(e.src)
        strm.write(1'u64)
    strm.close()


