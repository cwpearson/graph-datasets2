import streams
import system
import strutils
import sequtils
import algorithm
import tables
import os

import edge
import twitter_dataset

proc convert *(src: string, dst:string): int {.discardable.} = 
    echo "converting ", src, " to ", dst

    var edges: seq[Edge]

    var canonical = initTable[uint64, uint64]()
    var nextId = 0'u64

    echo "opening ", src
    var lineCount = 0'i64

    var twitter = Twitter(path: src)
    var strm = newFileStream(src, fmRead)
    var edge: Edge
    if not isNil(strm):
        while twitter.readEdge(edge):
            var user = edge.src
            var follower = edge.dst
            if not canonical.hasKey(user):
                canonical[user] = nextId
                nextId += 1
            if not canonical.hasKey(follower):
                canonical[follower] = nextId
                nextId += 1
            var src = canonical[user]
            var dst = canonical[follower]
            edges.add(newEdge(src, dst))
            edges.add(newEdge(dst, src))
            lineCount += 1
            if lineCount %% 1000000'i64 == 0:
                echo lineCount
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


