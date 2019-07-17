import streams
import system
import strutils
import sequtils
import algorithm
import tables
import os
import sets
import math

import ../edge
import ../bel_file
import ../format
import ../logger

type Stats = tuple
    numEdges: uint64
    numVerts: uint64
    minDeg: uint64
    maxDeg: uint64
    avgDeg: float
    stddevDeg: float

proc initStats(): Stats =
    return Stats (
        numEdges: 0'u64,
        numVerts: 0'u64,
        minDeg: 18_446_744_073_709_551_615'u64, # 2^64 - 1
        maxDeg: 0'u64,
        avgDeg: 0.0,
        stddevDeg: Inf,
    )

proc count (path: string): int {.discardable.} =
    let datasetKind = guessFormat(path)

    case datasetKind
    of dkBel:
        debug("open ", path)
        let bel = openBel(path, fmRead)
        defer: bel.close()
        var stats = initStats()
        let
            sz = getFileSize(path)
            edge_est = sz div 24
            vert_est = edge_est div 5 #
        debug("estimate ", edge_est, " edges -> ", vert_est, " verts")
        var deg = initTable[uint64, uint64](tables.rightSize(vert_est))

        debug("determine degrees ", path)
        for edge in bel.edges():
            stats.numEdges += 1
            let d1 = deg.getOrDefault(edge.src)
            deg[edge.src] = d1+1
            let d2 = deg.getOrDefault(edge.dst)
            deg[edge.dst] = d2

        stats.numVerts = uint64(len(deg))

        debug("summarize degrees (1/2)")
        var total = uint64(0)
        for _, outdeg in deg:
            total += outdeg
            stats.minDeg = min(stats.minDeg, outdeg)
            stats.maxDeg = max(stats.maxDeg, outdeg)
        stats.avgDeg = float(total) / float(len(deg))

        debug("summarize degrees (2/2)")
        var std_dev = 0.0
        for _, outdeg in deg:
            std_dev += pow(float(outdeg) - stats.avgDeg, 2)
        std_dev /= float(len(deg) - 1)
        std_dev = math.sqrt(std_dev)
        stats.stddevDeg = std_dev


        echo stats
    else:
        echo "ERROR can't count for ", path, " of kind ", datasetKind
        quit(1)

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
