import streams
import system
import strutils
import sequtils
import algorithm
import tables
import os

import ../edge
import ../bel_file
import ../format
import ../logger

type Method* = enum
    mCompact
    mRandom

proc relabelBel(input_path, output_path: string): int {.discardable.} =

    info("open ", input_path)
    let bel = openBel(input_path, fmRead)
    defer: bel.close()
    let orientation = mCompact

    var edges: seq[Edge]

    case orientation
    of mCompact:
        # compute degree of each node
        info("count vert degrees")
        let
            sz = getFileSize(input_path)
            edge_est = sz div 24
            vert_est = edge_est div 10 #
        debug("est edges: ", edge_est, " est verts: ", vert_est)
        var hist = initTable[uint64, uint64](tables.rightSize(vert_est))
        for edge in bel.edges():
            let d1 = hist.getOrDefault(edge.src)
            hist[edge.src] = d1 + 1
            let d2 = hist.getOrDefault(edge.dst)
            hist[edge.dst] = d2 + 1


        info("sort verts by degree (descending)")
        proc mycmp(x, y: tuple[v: uint64, d: uint64]): int =
            if x.d == y.d:
                if x.v == y.v:
                    return 0
                if x.v > y.v:
                    return -1
                return 1
            if x.d > y.d:
                return -1
            return 1
        var srcp = toSeq(pairs(hist))
        sort(srcp, mycmp)

        echo "compute new vert labels by sorted position"
        var dstp = initTable[uint64, uint64](tables.rightSize(len(srcp)))
        for i, (v, d) in srcp:
            dstp[v] = uint64(i)
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

    info("write ", len(edges), " edges to ", output_path)

    # sort edges by src
    sort(edges, bel_file.cmp)
    let out_bel = openBel(output_path, fmWrite)
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
