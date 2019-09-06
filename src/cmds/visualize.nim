import streams
import system
import strutils
import sequtils
import algorithm
import tables
import os
import sets
import math
import strformat

import ../edge
import ../bel
import ../tsv
import ../mtx
import ../bmtx
import ../format
import ../logger
import ../edge_stream
import ../bmp


proc visualize (input, output: string) =
    info("open " & $input)
    var es = guessEdgeStreamReader(input)
    if es == nil:
        error(&"can't count {input}")
        quit(1)

    let
        width = 100
        height = 100


    var bins = newImage[int](width, height)

    info(&"get max node")
    var maxNode = -1

    for edge in edges(es):
        maxNode = max(maxNode, edge.src)
        maxNode = max(maxNode, edge.dst)
    maxNode += 1

    for edge in edges(es):
        let
            sidx = int(float(edge.src) / float(maxNode) * width.float)
            didx = int(float(edge.dst) / float(maxNode) * height.float)
        bins.mget(sidx, didx) += 1
    # echo bins.data

    # log of bins
    for i, v in bins.data:
        if v != 0:
            bins.data[i] = int(log2(v.float))
    # echo bins.data

    # normalize to 255
    let
        maxVal = max(bins.data)
    for i, v in bins.data:
        bins.data[i] = int(v.float * 255.0 / maxVal.float)
    # echo bins.data

    var s = openFileStream(output, fmWrite)
    bins.save(s)
    s.close()


proc doVisualize *[T](opts: T) =
    visualize(opts.input, opts.output)

