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


proc headerStr(delim = ","): string =
    ["path", "num_rows", "num_cols", "nnz",
    "fill",
    "min_row_nz", "max_row_nz",
    "avg_row_nz",
    "std_row_nz", "empty_rows",
    "min_col_nz", "max_col_nz",
    "avg_col_nz",
    "std_col_nz", "empty_cols",
    ].join(delim)

proc rowStr(path: string, s: Stats, delim = ","): string =
    [path, $s.numRows, $s.numCols, $s.numNonZeros,
     $(s.numNonZeros.float / float(s.numRows * s.numCols)),
     $s.minRowNonZeros, $s.maxRowNonZeros,
     $(s.numNonZeros.float / s.numRows.float),
     $s.stdRowNonZeros, $s.numEmptyRows,
     $s.minColNonZeros, $s.maxColNonZeros,
     $(s.numNonZeros.float / s.numCols.float),
     $s.stdColNonZeros, $s.numEmptyCols,
    ].join(delim)

proc countOne (path: string, formatStr: string = "unknown"): int =
    result = 0
    info("open ", path)
    let format: DatasetKind = fromStr(formatStr)
    var es = guessEdgeStreamReader(path, format)
    if es == nil:
        error(&"can't count {path}")
        return 1


    var stats = initStats()
    var rowNZ = initTable[int, int]()
    var colNz = initTable[int, int]()

    info("matrix size ", path)
    let (numRows, numCols, numNonZeros) = es.getMatrixSize()
    stats.numRows = numRows
    stats.numCols = numCols
    stats.numNonZeros = numNonZeros
    debug(&"{stats.numRows} rows")
    debug(&"{stats.numCols} cols")
    debug(&"{stats.numNonZeros} nnz")

    info("count vert degrees ", path)
    for i, edge in es:
        let d1 = rowNZ.getOrDefault(edge.src)
        rowNZ[edge.src] = d1+1
        let d2 = colNZ.getOrDefault(edge.dst)
        colNZ[edge.dst] = d2+1
        if i mod (1024 * 1024) == 0:
            info(&"edge {i}...")
    es.close()

    info("summarize degrees (1/4)")
    for row in 0..<numRows:
        let rowNNZ = rowNZ.getOrDefault(row, 0)
        stats.minRowNonZeros = min(stats.minRowNonZeros, rowNNZ)
        stats.maxRowNonZeros = max(stats.maxRowNonZeros, rowNNZ)
        if rowNNZ == 0:
            stats.numEmptyRows += 1

    info("summarize degrees (2/4)")
    for col in 0..<numCols:
        let colNNZ = colNZ.getOrDefault(col, 0)
        stats.minColNonZeros = min(stats.minColNonZeros, colNNZ)
        stats.maxColNonZeros = max(stats.maxColNonZeros, colNNZ)
        if colNNZ == 0:
            stats.numEmptyCols += 1

    info("summarize degrees (3/4)")
    var std_dev = 0.0
    for row in 0..<stats.numRows:
        let outdeg = rowNZ.getOrDefault(row, 0)
        std_dev += pow(float(outdeg) - stats.avgRowNnz(), 2)
    std_dev /= float(stats.numRows - 1)
    std_dev = math.sqrt(std_dev)
    stats.stdRowNonZeros = std_dev

    info("summarize degrees (4/4)")
    std_dev = 0.0
    for col in 0..<stats.numCols:
        let outdeg = colNZ.getOrDefault(col, 0)
        std_dev += pow(float(outdeg) - stats.avgColNnz(), 2)
    std_dev /= float(stats.numCols - 1)
    std_dev = math.sqrt(std_dev)
    stats.stdColNonZeros = std_dev

    echo rowStr(path, stats)

proc countAll (paths: seq[string], formatStr: string = "unknown"): int =
    echo headerStr()
    result = 0
    for path in paths:
        notice(path)
        if countOne(path, formatStr) != 0:
            result = 1



proc countCli*(format = "unknown", debug = false,
        verbose = false, inputs: seq[string]): int =
    setLevel(lvlNotice)
    if debug:
        setLevel(lvlDebug)
    if verbose:
        setLevel(lvlAll)
    countAll(inputs, format)

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
