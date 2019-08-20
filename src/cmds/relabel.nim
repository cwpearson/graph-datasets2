import streams
import system
import strutils
import sequtils
import algorithm
import os
import random
import strformat

import ../edge
import ../bel
import ../format
import ../logger
import ../dict
import ../edge_stream
import ../graph_challenge

type Method* = enum
    mCompact
    mRandom

proc relabel(input_path, output_path: string, m: Method, seed: int = 0) =

    info("open ", input_path)
    var ins = guessEdgeStreamReader(input_path)



    case m:
    of mCompact:

        var edges: seq[Edge]
        # compute degree of each node
        info("pass 1: count vert degrees")
        var hist = initDict[int, int]()
        var nnz = 0
        for i, edge in ins:
            let d1 = hist.getOrDefault(edge.src)
            hist[edge.src] = d1 + 1
            let d2 = hist.getOrDefault(edge.dst)
            hist[edge.dst] = d2 + 1
            nnz += 1
            if i mod (1024 * 1024) == 0 and i != 0:
                debug("read ", i, " edges...")
        ins.close()


        info("sort verts by degree (descending)")
        proc mycmp(x, y: tuple[v: int, d: int]): int =
            if x.d == y.d:
                if x.v == y.v:
                    return 0
                if x.v > y.v:
                    return -1
                return 1
            if x.d > y.d:
                return -1
            elif x.d < y.d:
                return 1
            return
        var srcp = toSeq(pairs(hist))
        sort(srcp, mycmp)

        info("compute new vert labels by sorted position")
        var dstp = initDict[int, int]()
        for i, (v, d) in srcp:
            dstp[v] = int(i)
        # echo dstp

        # relabel edges
        info("pass 2: rewrite edges with new labels")
        ins = guessEdgeStreamReader(input_path)
        var os = guessEdgeStreamWriter(output_path, len(dstp), len(dstp), nnz)
        for edge in ins.edges():
            let new_src = dstp[edge.src]
            let new_dst = dstp[edge.dst]
            os.writeEdge(initEdge(new_src, new_dst, edge.weight))

        info("write ", len(edges), " edges to ", output_path)
        let out_bel = openBelStream(output_path, fmWrite)
        defer: out_bel.close()
        for edge in edges:
            out_bel.writeEdge(edge)


    of mRandom:
        if seed != 0:
            info(&"seed = {seed}")
            randomize(seed)

        notice("pass 1: count nodes")
        var
            numNodes = 0
            nnz = 0
        for edge in edges(ins):
            numNodes = max(edge.src, numNodes)
            numNodes = max(edge.dst, numNodes)
            nnz += 1
        ins.close()

        notice("shuffling labels")
        var newIds = toSeq[0..numNodes]
        shuffle(newIds)

        notice("pass 2: relabel edges")
        var os = guessEdgeStreamWriter(output_path, numNodes+1, numNodes+1, nnz)
        ins = guessEdgeStreamReader(input_path)
        for edge in ins:
            let src = newIds[edge.src]
            let dst = newIds[edge.dst]
            os.writeEdge(initEdge(src, dst, edge.weight))




proc doRelabel *[T](opts: T): int {.discardable.} =
    let m = case opts.kind:
    of "compact": mCompact
    of "random": mRandom
    else:
        error(&"unexpected kind {opts.kind}")
        quit(1)

    let seed = parseInt(opts.seed)
    relabel(opts.input, opts.output, m = m, seed = seed)
