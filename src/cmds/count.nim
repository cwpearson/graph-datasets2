import streams
import system
import strutils
import sequtils
import tables
import os
import math
import strformat

import ../edge
import ../format
import ../logger
import ../edge_stream

type Stats = tuple
    numNonZeros: int
    numRows: int
    minRowNonZeros: int
    maxRowNonZeros: int
    stdRowNonZeros: float
    numEmptyRows: int
    numCols: int
    minColNonZeros: int
    maxColNonZeros: int
    stdColNonZeros: float
    numEmptyCols: int

proc initStats(): Stats =
    return Stats (
        numNonZeros: 0,
        numRows: 0,
        minRowNonZeros: int.high,
        maxRowNonZeros: int.low,
        stdRowNonZeros: 0.0,
        numEmptyRows: 0,
        numCols: 0,
        minColNonZeros: int.high,
        maxColNonZeros: int.low,
        stdColNonZeros: 0.0,
        numEmptyCols: 0,
    )

proc avgRowNnz(s: Stats): float =
    s.numNonZeros.float / s.numRows.float

proc avgColNnz(s: Stats): float =
    s.numNonZeros.float / s.numCols.float

proc count (path: string, formatStr: string = "unknown"): int {.discardable.} =
    info("open ", path)
    let format: DatasetKind = fromStr(formatStr)
    var es = guessEdgeStreamReader(path, format)
    if es == nil:
        error(&"can't count {path}")
        quit(1)


    var stats = initStats()
    var rowNZ = initTable[int, int]()
    var colNz = initTable[int, int]()

    info("count vert degrees ", path)
    for i, edge in es:
        stats.numNonZeros += 1
        let d1 = rowNZ.getOrDefault(edge.src)
        rowNZ[edge.src] = d1+1
        let d2 = colNZ.getOrDefault(edge.dst)
        colNZ[edge.dst] = d2+1
        if i mod (1024 * 1024) == 0:
            info(&"edge {i}...")

    stats.numRows = len(rowNZ)
    stats.numCols = len(colNZ)
    debug(&"{stats.numRows} rows")
    debug(&"{stats.numCols} cols")

    info("summarize degrees (1/4)")
    for _, rowNNZ in rowNZ:
        stats.minRowNonZeros = min(stats.minRowNonZeros, rowNNZ)
        stats.maxRowNonZeros = max(stats.maxRowNonZeros, rowNNZ)
        if rowNNZ == 0:
            stats.numEmptyRows += 1

    info("summarize degrees (2/4)")
    for _, colNNZ in colNZ:
        stats.minColNonZeros = min(stats.minColNonZeros, colNNZ)
        stats.maxColNonZeros = max(stats.maxColNonZeros, colNNZ)
        if colNNZ == 0:
            stats.numEmptyCols += 1


    info("summarize degrees (3/4)")
    var std_dev = 0.0
    for _, outdeg in rowNZ:
        std_dev += pow(float(outdeg) - stats.avgRowNnz(), 2)
    std_dev /= float(len(rowNZ) - 1)
    std_dev = math.sqrt(std_dev)
    stats.stdRowNonZeros = std_dev

    info("summarize degrees (4/4)")
    std_dev = 0.0
    for _, outdeg in colNZ:
        std_dev += pow(float(outdeg) - stats.avgColNnz(), 2)
    std_dev /= float(len(colNZ) - 1)
    std_dev = math.sqrt(std_dev)
    stats.stdColNonZeros = std_dev


    echo stats
    es.close()


proc doCount *[T](opts: T): int {.discardable.} =
    count(opts.input, formatStr = opts.format)

when isMainModule:
    import times
    import hashes
    import sets
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
