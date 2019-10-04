import streams
import strutils
import os
import math
import strformat

import ../edge
import ../format
import ../logger
import ../edge_stream
import ../bmp


proc visualize (input, output: string, size: int, noLog: bool) =
    info("open " & $input)
    var es = guessEdgeStreamReader(input)
    if es == nil:
        error(&"can't count {input}")
        quit(1)

    let
        width = size
        height = size

    var bins = newImage[int](width, height)

    notice(&"pass 1: counting nodes")
    var maxNode = -1
    for edge in edges(es):
        maxNode = max(maxNode, edge.src)
        maxNode = max(maxNode, edge.dst)
    info(&"max node was {maxNode}")
    maxNode += 1

    notice(&"pass 2: binning edges")
    for edge in edges(es):
        let
            sidx = int(float(edge.src) / float(maxNode) * width.float)
            didx = int(float(edge.dst) / float(maxNode) * height.float)
        bins.mget(sidx, didx) += 1
    # echo bins.data

    # conver to float
    info(&"convert to float")
    var floatBins = newImage[float](width, height)
    for x, y, p in items(bins):
        floatBins[x, y] = p.float
    # echo floatBins.data

    # log of bins
    if not noLog:
        info(&"log(count+1)")
        for x, y, v in items(floatBins):
            if v != 0:
                floatBins[x, y] = log2(v+1) # 0 -> 0, 1 -> 1, 2->1.6, 3->2
            else:
                floatBins[x, y] = v
        # echo floatBins.data

    # normalize to 255
    info(&"normalize to 0-255")
    let
        maxVal = max(floatBins.data)
    info(&"max val pre-normalization was {maxVal}")
    if maxVal == 0:
        warn(&"scaled bin count is always 0. Try reducing output size")

    for x, y, v in items(floatBins):
        if maxVal != 0:
            floatBins[x, y] = v * 255.0 / maxVal
        else:
            floatBins[x, y] = 0.0
        if floatBins[x, y] < 0:
            echo &"{x} {y}", " ", v, " ", floatBins[x, y], &" {v * 255.0}, {v * 255.0 / maxVal.float}"
        assert floatBins[x, y] >= 0
        assert floatBins[x, y] < 256
    # echo max(floatBins.data)

    # convert back to int
    info(&"convert to ints")
    for x, y, p in items(floatBins):
        bins[x, y] = p.int
    # echo max(bins.data)

    notice(&"save to {output}")
    var s = openFileStream(output, fmWrite)
    bins.save(s)
    s.close()


proc doVisualize *[T](opts: T) =
    let
        size = parseInt(opts.size)
    visualize(opts.input, opts.output, size, opts.no_log)

