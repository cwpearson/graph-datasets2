import streams
import strutils
import math
import strformat

import ../edge
import ../format
import ../logger
import ../edge_stream
import ../bmp


proc visualize (input, output: string, imgHeightHint, imgWidthHint: int,
        matHeightHint, matWidthHint: int, noLog: bool) =
    info("open " & $input)
    var es = guessEdgeStreamReader(input)
    if es == nil:
        error(&"can't count {input}")
        quit(1)

    notice(&"pass 1: matrix dimensions")
    var
        maxCol = -1
        maxRow = -1
    for edge in edges(es):
        maxRow = max(maxRow, edge.src)
        maxCol = max(maxCol, edge.dst)
    info(&"max row/cols were {maxRow}/{maxCol}")
    let matWidth = if matWidthHint != 0:
        matWidthHint
    else:
        maxCol + 1
    let matHeight = if matHeightHint != 0:
        matHeightHint
    else:
        maxRow + 1


    var imgWidth, imgHeight: int
    if imgHeightHint != 0:
        imgHeight = imgHeightHint
        imgWidth = int(imgHeightHint.float * matWidth.float / matHeight.float)
    elif imgWidthHint != 0:
        imgWidth = imgWidthHint
        imgHeight = int(imgWidthHint.float * matWidth.float / matHeight.float)
    else:
        imgWidth = int(1000.0 * matWidth.float / max(matWidth, matHeight).float)
        imgHeight = int(1000.0 * matHeight.float / max(matWidth,
                matHeight).float)
    info(&"image dimensions are {imgWidth}x{imgHeight}")


    var bins = newImage[int](imgWidth, imgHeight)


    notice(&"pass 2: binning edges")
    for edge in edges(es):
        let
            sidx = int(float(edge.src) / float(matHeight) * imgHeight.float)
            didx = int(float(edge.dst) / float(matWidth) * imgWidth.float)
        bins.mget(didx, sidx) += 1
    # echo bins.data

    info(&"convert to float")
    var floatBins = newImage[float](imgWidth, imgHeight)
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
        imgHeightHint = parseInt(opts.img_height)
        imgWidthHint = parseInt(opts.img_width)
        matHeightHint = parseInt(opts.mat_height)
        matWidthHint = parseInt(opts.mat_height)
    visualize(opts.input, opts.output, imgHeightHint, imgWidthHint,
            matHeightHint, matWidthHint, opts.no_log)

