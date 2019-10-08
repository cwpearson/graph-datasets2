import system
import strutils
import os
import strformat

import ../edge
import ../format
import ../logger
import ../dict
import ../edge_stream

type Orientation* = enum
    oLowerTriangular
    oUpperTriangular
    oDegree

proc orientEdgeStream(inputPath: string, outputPath: string,
        kind: Orientation) =

    notice(&"orient {inputPath} -> {outputPath}")
    var srces = guessEdgeStreamReader(inputPath)


    # pass 1: count how many edges will be output
    var
        rows = 0
        cols = 0
        entries = 0

    for _, edge in srces:
        if edge.src > edge.dst:
            rows = max(rows, edge.src)
            cols = max(cols, edge.dst)
            entries += 1
        if entries > 0:
            rows += 1 # number of rows instead of largest row
            cols += 1

    info(&"output will have {rows} rows, {cols} cols, {entries} entries")
    if entries == 0:
        warn(&"{outputPath} will have 0 entries")

    # pass 2: write the file
    var dstes = guessEdgeStreamWriter(outputPath, rows, cols, entries)
    case kind
    of oLowerTriangular:
        for _, edge in srces:
            if edge.src > edge.dst:
                dstes.writeEdge(edge)
    of oUpperTriangular:
        for _, edge in srces:
            if edge.src < edge.dst:
                dstes.writeEdge(edge)
    of oDegree:
        # compute degree of each node
        info("determine vert degrees")
        var degrees = initDict[int, int]()
        for edge in srces.edges():
            let d1 = degrees.getOrDefault(edge.src)
            degrees[edge.src] = d1 + 1
            let d2 = degrees.getOrDefault(edge.dst)
            degrees[edge.src] = d2 + 1

        info("orient edges by degree")
        var edges: seq[Edge]
        for edge in srces.edges():
            if degrees[edge.src] == degrees[edge.dst]:
                if edge.src < edge.dst:
                    edges.add(edge)
            elif degrees[edge.src] < degrees[edge.dst]:
                edges.add(edge)

        info("write ", len(edges), " edges")

        for edge in edges:
            dstes.writeEdge(edge)


    srces.close()
    dstes.close()


proc orient *(input_path, output_path: string, kind: Orientation): int {.discardable.} =
    let datasetKind = guessFormat(input_path)

    case datasetKind
    of dkBel, dkMtx, dkTsv, dkBmtx:
        orientEdgeStream(input_path, output_path, kind)
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
