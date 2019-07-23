import streams
import system
import strutils
import sequtils
import algorithm
import os

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

proc relabelBel(input_path, output_path: string): int {.discardable.} =

    info("open ", input_path)
    let bel = openBelStream(input_path, fmRead)
    defer: bel.close()
    let orientation = mCompact

    var edges: seq[Edge]

    case orientation
    of mCompact:
        # compute degree of each node
        info("count vert degrees")
        var hist = initDict[int, int]()
        for i, edge in bel:
            let d1 = hist.getOrDefault(edge.src)
            hist[edge.src] = d1 + 1
            let d2 = hist.getOrDefault(edge.dst)
            hist[edge.dst] = d2 + 1
            if i mod (1024 * 1024) == 0 and i != 0:
                debug("read ", i, " edges...")


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

        echo "compute new vert labels by sorted position"
        var dstp = initDict[int, int]()
        for i, (v, d) in srcp:
            dstp[v] = int(i)
        # echo dstp

        # relabel edges
        echo "rewrite edges with new labels"
        for edge in bel.edges():
            let new_src = dstp[edge.src]
            let new_dst = dstp[edge.dst]
            edges.add(initEdge(new_src, new_dst))


    of mRandom:
        error("random relabel unimplemented")
        quit(1)



    # sort edges by src
    info("sort edges into graph challenge order")
    sort(edges, graph_challenge.cmp)

    info("write ", len(edges), " edges to ", output_path)
    let out_bel = openBelStream(output_path, fmWrite)
    defer: out_bel.close()
    for edge in edges:
        out_bel.writeEdge(edge)


proc relabel *(input_path, output_path: string): int {.discardable.} =
    let datasetKind = guessFormat(input_path)

    case datasetKind
    of dkBel:
        relabelBel(input_path, output_path)
    else:
        echo "ERROR can't relabel ", input_path, " of kind ", datasetKind
        quit(1)

proc doRelabel *[T](opts: T): int {.discardable.} =
    relabel(opts.input, opts.output)
