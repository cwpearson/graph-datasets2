import random
import math
import strformat
import sequtils
import algorithm
import os

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

proc generate(numNodes, nnz: int, g: float, output: string, force: bool,
        seed: int64 = 0) =

    if fileExists(output) or dirExists(output):
        if not force:
            error(&"{output} already exists")
            quit(1)

    if seed != 0:
        info(&"seed: {seed}")
        randomize(seed)



    var cumDegrees = newSeq[int](numNodes)
    let nodes = toSeq(0..<numNodes)


    proc update(node: int) =
        for i in node..<len(cumDegrees):
            cumDegrees[i] += 1

    var nnzRemaining = nnz

    var os = guessEdgeStreamWriter(output, numNodes, numNodes, nnz)



    # let initialNodes = (nnz + numNodes - 1) div numNodes
    # info(&"creating {initialNodes} initial nodes")
    # for src in 0..<initialNodes:
    #     for dst in (src+1)..<initialNodes:
    #         update(src)
    #         update(dst)
    #         os.writeEdge(initEdge(src, dst, 1))
    #         os.writeEdge(initEdge(dst, src, 1))
    #         nnzRemaining -= 1

    if numNodes > 1:
        let src = 0
        let dst = 1
        update(src)
        update(dst)
        os.writeEdge(initEdge(src, dst, 1))
        os.writeEdge(initEdge(dst, src, 1))
        nnzRemaining -= 1

    # add more nodes
    for dst in 2..<numNodes:
        let nodesRemaining = numNodes - dst

        echo &"node {dst} with {nnzRemaining} nnzs and {nodesRemaining} nodes left"

        # figure out how many edges we should create

        let numEdges = min(int(float(nnzRemaining) / float(nodesRemaining) +
                0.5), dst)
        # echo &"generating {numEdges} edges"

        var srcs: seq[int]
        while len(srcs) < numEdges:
            let src = sample(nodes, cumDegrees)
            # echo "try ", src
            if not (src in srcs):
                srcs.add(src)


        for src in srcs:
            update(dst)
            update(src)
            os.writeEdge(initEdge(src, dst, 1))
            os.writeEdge(initEdge(dst, src, 1))



        nnzRemaining -= len(srcs)

        # echo dst, " -> ", srcs
        # echo cumDegrees

    os.close()

when isMainModule:
    init()
    setLevel(lvlDebug)
    generate(1_000_000_000, 2_000_000_000, 2.0, "test.tsv", true)
