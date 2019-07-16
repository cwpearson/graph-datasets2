import streams
import system
import strutils
import sequtils
import algorithm
import tables
import os
import sets
import algorithm

import edge
import bel_file
import format

type Method * = enum
    mCompact
    mRandom

proc relabelBel(input_path, output_path: string): int {.discardable.} =

    echo "open ", input_path
    let bel = openBel(input_path, fmRead)
    defer: bel.close()
    let orientation = mCompact

    var edges: seq[Edge]

    case orientation
    of mCompact:
        # compute degree of each node
        echo "count vert degrees"
        var degrees: Table[uint64, uint64]
        for edge in bel.edges():
            let d1 = degrees.getOrDefault(edge.src)
            degrees[edge.src] = d1 + 1
            let d2 = degrees.getOrDefault(edge.dst)
            degrees[edge.src] = d2 + 1

        proc mycmp(x,y: tuple[v: uint64, d: uint64]): int = 
            if x.d == y.d:
                if x.v == y.v:
                    return 0
                if x.v > y.v:
                    return -1
                return 1
            if x.d > y.d:
                return -1
            return 1

        echo "sort verts by degree (descending)"
        var sortedVerts = toSeq(pairs(degrees))
        sort(sortedVerts, mycmp)

        echo "compute new vert labels by sorted position"
        var newVerts: Table[uint64, uint64]
        for i, (v, d) in sortedVerts:
            newVerts[v] = uint64(i)
        # echo newVerts

        # relabel edges
        echo "rewrite edges with new labels"
        for edge in bel.edges():
            let new_src = newVerts[edge.src]
            let new_dst = newVerts[edge.dst]
            edges.add(initEdge(new_src, new_dst))
                
    of mRandom:
        echo "ERROR unimplemented"
        quit(1)

    echo "write ", len(edges), " edges to ", output_path

    # sort edges by src
    sort(edges, bel_file.cmp)
    let out_bel = openBel(output_path, fmWrite)
    defer: out_bel.close()
    for edge in edges:
        out_bel.writeEdge(edge)
    echo "done"

    
proc orient *(input_path, output_path: string): int {.discardable.} = 
    let datasetKind = guessFormat(input_path)

    case datasetKind
    of dkBel:
        relabelBel(input_path, output_path)
    else:
        echo "ERROR can't relabel ", input_path, " of kind ", datasetKind
        quit(1)

