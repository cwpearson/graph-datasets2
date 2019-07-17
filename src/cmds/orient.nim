import system
import strutils
import sequtils
import algorithm
import tables
import os
import algorithm

import ../edge
import ../bel_file
import ../format
import ../logger

type Orientation* = enum
    oLowerTriangular
    oUpperTriangular
    oDegree

proc orientBel(input_path: string, output_path: string,
        kind: Orientation): int {.discardable.} =

    info("open ", input_path)
    let bel = openBel(input_path, fmRead)
    defer: bel.close()

    var edges: seq[Edge]

    case kind
    of oLowerTriangular:
        for edge in bel.edges():
            if edge.src > edge.dst:
                edges.add(edge)
    of oUpperTriangular:
        for edge in bel.edges():
            if edge.src < edge.dst:
                edges.add(edge)
    of oDegree:
        # compute degree of each node
        info("determine vert degrees")
        let
            sz = getFileSize(input_path)
            edge_est = sz div 24
            vert_est = edge_est div 20 #
        debug("est edges: ", edge_est, " est verts: ", vert_est)
        var degrees = initTable[uint64, uint64](tables.rightSize(vert_est))
        for edge in bel.edges():
            let d1 = degrees.getOrDefault(edge.src)
            degrees[edge.src] = d1 + 1
            let d2 = degrees.getOrDefault(edge.dst)
            degrees[edge.src] = d2 + 1

        info("orient edges by degree")
        for edge in bel.edges():
            if degrees[edge.src] == degrees[edge.dst]:
                if edge.src < edge.dst:
                    edges.add(edge)
            elif degrees[edge.src] < degrees[edge.dst]:
                edges.add(edge)

    info("write ", len(edges), " edges")

    info("open ", output_path)
    let out_bel = openBel(output_path, fmWrite)
    defer: out_bel.close()
    for edge in edges:
        out_bel.writeEdge(edge)



proc orient *(input_path, output_path: string, kind: Orientation): int {.discardable.} =
    let datasetKind = guessFormat(input_path)

    case datasetKind
    of dkBel:
        orientBel(input_path, output_path, kind)
    else:
        error("can't orient ", input_path, " of kind ", datasetKind)
        quit(1)

proc doOrient *[T](opts: T): int {.discardable.} =
    var kind: Orientation
    case opts.kind
    of "lower":
        kind = oLowerTriangular
    of "upper":
        kind = oUpperTriangular
    of "degree":
        kind = oDegree
    else:
        error("unexpected kind ", opts.kind)
        quit(1)
    orient(opts.input, opts.output, kind)
