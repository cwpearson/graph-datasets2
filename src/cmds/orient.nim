import system
import strutils
import sequtils
import algorithm
import os
import algorithm

import ../edge
import ../bel
import ../format
import ../logger
import ../dict
import ../edge_stream

type Orientation* = enum
    oLowerTriangular
    oUpperTriangular
    oDegree

proc orientBel(input_path: string, output_path: string,
        kind: Orientation): int {.discardable.} =

    info("open ", input_path)
    let bel = openBelStream(input_path, fmRead)
    defer: bel.close()



    case kind
    of oLowerTriangular:
        info("open ", output_path)
        let out_bel = openBelStream(output_path, fmWrite)
        defer: out_bel.close()
        for _, edge in bel:
            if edge.src > edge.dst:
                out_bel.writeEdge(edge)
    of oUpperTriangular:
        let out_bel = openBelStream(output_path, fmWrite)
        defer: out_bel.close()
        for _, edge in bel:
            if edge.src < edge.dst:
                out_bel.writeEdge(edge)
    of oDegree:
        # compute degree of each node
        info("determine vert degrees")
        var degrees = initDict[int, int]()
        for edge in bel.edges():
            let d1 = degrees.getOrDefault(edge.src)
            degrees[edge.src] = d1 + 1
            let d2 = degrees.getOrDefault(edge.dst)
            degrees[edge.src] = d2 + 1

        info("orient edges by degree")
        var edges: seq[Edge]
        for edge in bel.edges():
            if degrees[edge.src] == degrees[edge.dst]:
                if edge.src < edge.dst:
                    edges.add(edge)
            elif degrees[edge.src] < degrees[edge.dst]:
                edges.add(edge)

        info("write ", len(edges), " edges")

        info("open ", output_path)
        let out_bel = openBelStream(output_path, fmWrite)
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
