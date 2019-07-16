import streams
import system
import strutils
import sequtils
import algorithm
import tables
import os
import sets
import math

import edge
import bel_file
import format

type Stats = tuple
    numEdges: uint64
    numVerts: uint64
    minDeg: uint64
    maxDeg: uint64
    avgDeg: float
    stddevDeg: float

proc newStats(): Stats =
    return Stats (
        numEdges: 0'u64,
        numVerts: 0'u64,
        minDeg: 18_446_744_073_709_551_615'u64, # 2^64 - 1
        maxDeg: 0'u64,
        avgDeg: 0.0,
        stddevDeg: Inf,
    )

proc count *(path: string): int {.discardable.} = 
    let datasetKind = guessFormat(path)

    case datasetKind
    of dkBel:
        let bel = openBel(path, fmRead)
        var stats = newStats()
        var deg: Table[uint64, uint64]


        for edge in bel.edges():
            stats.numEdges += 1
            let d1 = deg.getOrDefault(edge.src)
            deg[edge.src] = d1+1
            let d2 = deg.getOrDefault(edge.dst)
            deg[edge.dst] = d2

        stats.numVerts = uint64(len(deg))

        var total = uint64(0)
        for _, outdeg in deg:
            total += outdeg
            stats.minDeg = min(stats.minDeg, outdeg)
            stats.maxDeg = max(stats.maxDeg, outdeg)
        stats.avgDeg = float(total) / float(len(deg))

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

