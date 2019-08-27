import plotly
import math
import sequtils
import strutils
import strformat

import ../format
import ../edge_stream
import ../edge

import ../logger

proc histogram(es: EdgeStream, output, title: string, width, height: int) =

    let d = Trace[int](`type`: PlotType.Histogram)

    notice(&"finding largest node")
    var maxNode = 0
    for edge in edges(es):
        maxNode = max(edge.src, maxNode)
        maxNode = max(edge.dst, maxNode)
    info(&"maxNode was {maxNode}")

    var degrees = newSeq[int](maxNode+1)

    notice(&"counting degrees")
    for edge in edges(es):
        degrees[edge.src] += 1

    # using ys will make a horizontal bar plot
    # using xs will make a vertical.
    d.xs = degrees

    notice(&"generate layout")
    let autosize = (height <= 0) or (width <= 0)
    let
        layout = Layout(title: title, width: width, height: height,
                        xaxis: Axis(title: "degree"),
                        yaxis: Axis(title: "count", ty: AxisType.Log),
                        autosize: autosize)
        p = Plot[int](layout: layout, traces: @[d])

    if output != "":
        notice(&"saving to {output}")
        if autosize:
            warn(&"saving may not work unless --width and --height provided")
        p.show(filename = output, onlySave = true)
    else:
        p.show()


proc doHistogram *[T](opts: T) =
    var es = guessEdgeStreamReader(opts.input)
    let
        width = parseInt opts.width
        height = parseInt opts.height
    histogram(es, opts.output, opts.title, width, height)
