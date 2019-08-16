import random
import math
import strformat
import sequtils
import algorithm
import os
import bitops
import hashes

import ../logger
import ../init
import ../format
import ../edge_stream
import ../edge



proc power(x0, x1, n: float64): float64 =
    ## selects a random number from the power-law distribution
    ## between x0 and x1 with power n
    ## http://mathworld.wolfram.com/RandomNumber.html
    let r = rand(0.0..1.0)
    let u = pow(x1, n+1)
    let l = pow(x0, n+1)
    let e = 1'f64/(n+1)
    # echo "l,u,r = ", l, ",", u, ",", r, ",", e
    result = pow(l + (u-l)*r, e)

proc power(x0, x1: int, n: float64): int =
    let raw = power(float64(x0), float64(x1) + 1, n)
    # echo "raw: ", raw
    result = int(raw)
    # echo "result: ", result

proc power(x0, x1: int64, n: float64): int64 =
    let raw = power(float64(x0), float64(x1) + 1, n)
    # echo "raw: ", raw
    result = int64(raw)
    # echo "result: ", result

proc generate(numNodes, nnz: int64, g: float, output: string, force: bool,
        seed: int64 = 0) =

    if fileExists(output) or dirExists(output):
        if not force:
            error(&"{output} already exists")
            quit(1)

    if seed != 0:
        info(&"seed: {seed}")
        randomize(seed)


    var targetNnzPerRow = newSeq[uint64](numNodes)
    var actualNnzPerRow = newSeq[uint64](numNodes)

    # compute the target number of non-zeros per row
    notice(&"compute target nnzs per row")
    for i in 0..<nnz:
        if (i mod (1024 * 1024)) == 0:
            info(&"nnzs: {float(i) / float(nnz) * 100:>5.2f}% ({i}/{nnz})")
        let r = power(0, numNodes-1, g)
        targetNnzPerRow[r] += 1

    # echo targetNnzPerRow

    # no row can have a greater degree than the number of preceeding rows
    # that have a non-zero degree (except the first non-zero row!)
    # since all rows only connect to lower-id rows
    # push degree to higher rows
    notice(&"tweak target nnzs per row")
    var nodesSoFar = 0'u64
    for i in 0..<(numNodes - 1):

        if (i mod (1024 * 1024)) == 0:
            info(&"tweak: {i}/{numNodes}")

        if targetNnzPerRow[i] > nodesSoFar:
            if nodesSoFar == 0:
                # smalles node id with non-zero degree

                # if the first node with a non-zero degree is greater than 1, we can't fill it with this algorithm
                # bump its required edges up a node
                if targetNnzPerRow[i] > 1'u64:
                    targetNnzPerRow[i + 1] += targetNnzPerRow[i] - 1
                    targetNnzPerRow[i] = 1

                nodesSoFar += 1
                continue

            # if the node wants to connect to more lower nodes that exist,
            # bump the extra up to the next node
            let bumpUp = targetNnzPerRow[i] - nodesSoFar
            targetNnzPerRow[i+1] += bumpUp
            targetNnzPerRow[i] = nodesSoFar
            nodesSoFar += 1

    # echo targetNnzPerRow

    if targetNnzPerRow[numNodes - 1] > uint64(numNodes) - 1:
        targetNnzPerRow[numNodes - 1] = uint64(numNodes) - 1
        error(&"last row too big seed:{seed}, numNodes:{numNodes} nnz:{nnz} g:{g}")
        quit(1)

    # echo targetNnzPerRow



    # start with the largest nodes and create their edges
    notice(&"generate edges")
    for src in countdown(numNodes-1, 0):

        if (src mod (1024 * 1024)) == 0:
            info(&"generate: {src}/{numNodes}")

        # echo &"row {src} needs {targetNnzPerRow[src]}"

        # connect to lower-id rows that need an edge
        for dst in countdown(src-1, 0):
            # done: degree has met its target
            if actualNnzPerRow[src] >= targetNnzPerRow[src]:
                break

            # the dst needs more degree
            if actualNnzPerRow[dst] < targetNnzPerRow[dst]:
                actualNnzPerRow[src] += 1
                actualNnzPerRow[dst] += 1
                # echo &"{src} -> {dst}"
                # echo &"{dst} -> {src}"
        if actualNnzPerRow[src] < targetNnzPerRow[src]:
            error(&"didn't fill row {src}")
            echo targetNnzPerRow
            echo actualNnzPerRow
            quit(1)



    if targetNnzPerRow != actualNnzPerRow:
        error(&"didn't match target seed:{seed}, numNodes:{numNodes} nnz:{nnz} g:{g}")
        echo "target: ", targetNnzPerRow
        echo "actual: ", actualNnzPerRow
        quit(1)

    # os.close()


when isMainModule:
    init()
    setLevel(lvlDebug)

    var seed = 0'i64
    while true:
        generate(100_000_000, 300_000_000, 2.5, "test.tsv", true, seed)
        seed += 1







