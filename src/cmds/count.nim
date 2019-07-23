import streams
import system
import strutils
import sequtils
import algorithm
import tables
import os
import sets
import math
import strformat

import ../edge
import ../bel
import ../tsv
import ../mtx
import ../bmtx
import ../format
import ../logger
import ../edge_stream

type Stats = tuple
    numEdges: int
    numVerts: int
    minDeg: int
    maxDeg: int
    avgDeg: float
    stddevDeg: float
    deg0Verts: int

proc initStats(): Stats =
    return Stats (
        numEdges: 0,
        numVerts: 0,
        minDeg: int.high,
        maxDeg: 0,
        avgDeg: 0.0,
        stddevDeg: Inf,
        deg0Verts: 0,
    )


proc count (path: string): int {.discardable.} =
    info("open ", path)
    var es = guessEdgeStreamReader(path)
    if es == nil:
        error(&"can't count {path}")
        quit(1)



    var stats = initStats()
    let
        sz = getFileSize(path)
        edge_est = sz div 24
        vert_est = edge_est div 1 #
    debug("estimate ", edge_est, " edges -> ", vert_est, " verts")
    var deg = initTable[int, int](tables.rightSize(vert_est))
    # var deg: Table[int, int]

    info("count vert degrees ", path)
    for i, edge in es:
        stats.numEdges += 1
        let d1 = deg.getOrDefault(edge.src)
        deg[edge.src] = d1+1
        let d2 = deg.getOrDefault(edge.dst)
        deg[edge.dst] = d2
        if i mod (1024 * 1024) == 0:
            info(&"edge {i}...")

    stats.numVerts = len(deg)
    debug(&"{stats.numVerts} verts")

    info("summarize degrees (1/2)")
    var total = 0
    for _, outdeg in deg:
        total += outdeg
        stats.minDeg = min(stats.minDeg, outdeg)
        stats.maxDeg = max(stats.maxDeg, outdeg)
        if outdeg == 0:
            stats.deg0Verts += 1
    stats.avgDeg = float(total) / float(len(deg))

    info("summarize degrees (2/2)")
    var std_dev = 0.0
    for _, outdeg in deg:
        std_dev += pow(float(outdeg) - stats.avgDeg, 2)
    std_dev /= float(len(deg) - 1)
    std_dev = math.sqrt(std_dev)
    stats.stddevDeg = std_dev


    echo stats
    es.close()


proc doCount *[T](opts: T): int {.discardable.} =
    count(opts.input)

when isMainModule:
    import times
    import hashes
    import random
    # import nimprof

    var hs1: HashSet[uint64]
    var hs2: HashSet[uint64]
    var hs3: HashSet[uint64]

    # insert 0..100k twice
    var time = cpuTime()
    for i in 0..100_000:
        let k1 = uint64(i)
        let k2 = uint64(i)
        hs1.incl(k1)
        hs1.incl(k2)
    echo "time ", (cpuTime() - time)

    # insert 0..100k and 100k..200k
    time = cpuTime()
    for i in 0..100_000:
        let k1 = uint64(i)
        let k2 = uint64(i + 100_000)
        hs1.incl(k1)
        hs1.incl(k2)
    echo "time ", (cpuTime() - time)

    # insert 0..100k and 1.0M..1.1M
    time = cpuTime()
    for i in 0..100_000:
        let k1 = uint64(i)
        let k2 = uint64(i + 1_000_000)
        hs1.incl(k1)
        hs1.incl(k2)
    echo "time ", (cpuTime() - time)
