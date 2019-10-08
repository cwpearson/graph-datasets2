import math
import strformat
import os
import algorithm
import strutils

import ../logger
import ../format
import ../edge_stream
import ../edge

iterator enumerate[T](a: openArray[T]): (int, T) =
    var i = 0
    for e in a:
        yield (i, e)
        i += 1

proc getNnz(N: int, g, c: float): int =
    assert c > 0
    var cnt: int = 0
    for i in 1 .. N:
        let raw = c * pow(float(i), -1.0 * g)
        try:
            cnt += int(raw + 0.5) + 1
        except OverflowError:
            # this could also be an underflow, but raw should always be positive
            echo "overflow, return max"
            return high(int)
    return cnt

proc nnzPerRow(N: int, g, c: float): seq[int] =
    result = newSeq[int](N)
    for i in 1 .. N:
        let raw = c * pow(float(i), -1.0 * g)
        result[i-1] = int(raw + 0.5) + 1

proc searchForC(N, nnz: int, g: float): float =

    var ub = float(1e100)
    var lb = float(1e-100)
    var c = 1e10
    var prevC = 0.0
    var prevNnz = -1

    while true:
        info(&"try c = {c:e}...")
        let check = getNnz(N, g, c)
        info(&"...yielded {check} edges")

        if prevC == c:
            info(&"c unchanged")
            result = c
            break
        elif abs(c - prevC) / abs(min(prevC, c)) < 1:
            if check == prevNnz:
                info(&"nnz unchanged")
                result = c
                break
        if check < nnz:
            lb = c
        elif check > nnz:
            ub = c
        else:
            # echo &"c yielded {check} nnzs"
            result = c
            break
        prevC = c
        prevNnz = check
        c = pow(ub * lb, 0.5)


proc generate(numNodes, nnz: int, g: float, output: string, force: bool) =

    notice(&"generate with g = {g}, {numNodes} nodes and {nnz} non-zeros")

    notice(&"search for c...")
    let c = searchForC(numNodes, nnz, g)
    info(&"c = {c}")
    var targetNnzPerRow = nnzPerRow(numNodes, g, c)


    info(&"nnz in first 10 rows: {targetNnzPerRow[0..9]}")
    info(&"nnz in last  10 rows: {targetNnzPerRow[^10..^1]}")

    # count non-zeros
    # due to the fiull algorithm, there must be an even nnz
    var actualNnz = sum(targetNnzPerRow)
    if not (actualNnz mod 2 == 0):
        for e in mitems(targetNnzPerRow):
            if e != 0:
                e -= 1
                break
        actualNnz -= 1
    notice(&"found a power distribution with {actualNnz} edges (sought {nnz}) and {numNodes} nodes with g = {g} ")

    # ensure no node has more nnzs than there are nodes.
    for i, n in enumerate(targetNnzPerRow):
        if n > (numNodes - 1):
            error(&"row {i} has too many nnz {targetNnzPerRow[i]} > {numNodes}. Try reducing g or the requested number of non-zeros")
            quit(1)

    if targetNnzPerRow[0] < targetNnzPerRow[^1]:
        info("reverseing nnz array")
        targetNnzPerRow.reverse()

    # no node can connect to more nodes than come after it with nnzs
    notice(&"tweaking nnzs per row")
    var nnzsSoFar = 0
    for i in countdown(len(targetNnzPerRow)-1, 1):
        if nnzsSoFar == 0:
            if targetNnzPerRow[i] > 1:
                targetNnzPerRow[i-1] = targetNnzPerRow[i] - 1
                targetNnzPerRow[i] = 1
        else:
            if targetNnzPerRow[i] > nnzsSoFar:
                targetNnzPerRow[i-1] = targetNnzPerRow[i] - nnzsSoFar
                targetNnzPerRow[i] = nnzsSoFar
        if targetNnzPerRow[i] > 0:
            nnzsSoFar += 1

    if targetNnzPerRow[0] > nnzsSoFar:
        error(&"first row has too many non-zeros")
        quit(1)

    info(&"first 10 row lengths: {targetNnzPerRow[0..9]}")
    info(&"last 10 row lengths: {targetNnzPerRow[^10..^1]}")

    # generate edges
    notice(&"generate edges...")
    var actualNnzPerRow = newSeq[int](numNodes)
    var es = guessEdgeStreamWriter(output, numNodes, numNodes, actualNnz)
    # start with the largest nodes and create their edges

    nnzsSoFar = 0
    for src, n in enumerate(targetNnzPerRow):
        # echo &"row {src} needs {targetNnzPerRow[src]}"

        # connect to higher-id nodes that need an edge
        for dst in src + 1 ..< len(targetNnzPerRow):
            # done: degree has met its target
            if actualNnzPerRow[src] >= targetNnzPerRow[src]:
                break

            # the dst needs more degree
            if actualNnzPerRow[dst] < targetNnzPerRow[dst]:
                actualNnzPerRow[src] += 1
                actualNnzPerRow[dst] += 1
                es.writeEdge(initEdge(int(src), int(dst)))
                es.writeEdge(initEdge(int(dst), int(src)))
                nnzsSoFar += 2
                if (nnzsSoFar mod (1024 * 1024)) == 0:
                    info(&"generate edge: {nnzsSoFar}/{actualNnz} ({float(nnzsSoFar) / float(actualNnz) * 100:>5.2f}%) (row {src}/{numNodes})")

        if actualNnzPerRow[src] < targetNnzPerRow[src]:
            error(&"didn't fill row {src}. nnz in output file is incorrect")

    es.close()

proc doGenerate *[T](opts: T) =
    let verts = parseInt(opts.verts)
    let edges = parseInt(opts.edges)
    let g = parseFloat(opts.g)
    generate(verts, edges, g, opts.output, opts.force)

when isMainModule:
    init()
    setLevel(lvlInfo)

    let targetNodes = 1_000_000
    let targetNnz = 8_000_000
    let g = 1.0

    generate(targetNodes, targetNnz, g, "test.tsv", false)










