import plotly
import math
import sequtils
import strutils

import ../format
import ../edge_stream
import ../edge

proc histogram(es: EdgeStream, output, title: string, width, height: int) =

    let d = Trace[int](`type`: PlotType.Histogram)

    var maxNode = 0
    for edge in edges(es):
        maxNode = max(edge.src, maxNode)
        maxNode = max(edge.dst, maxNode)

    var degrees = newSeq[int](maxNode+1)

    for edge in edges(es):
        degrees[edge.src] += 1

    # using ys will make a horizontal bar plot
    # using xs will make a vertical.
    d.xs = degrees

    let
        layout = Layout(title: title, width: width, height: height,
                        xaxis: Axis(title: "degree"),
                        yaxis: Axis(title: "count", ty: AxisType.Log),
                        autosize: (height <= 0) or (width <= 0))
        p = Plot[int](layout: layout, traces: @[d])

    if output != "":
        p.show(filename = output, onlySave = true)
    else:
        p.show()


proc doHistogram *[T](opts: T) =
    var es = guessEdgeStreamReader(opts.input)
    let
        width = parseInt opts.width
        height = parseInt opts.height
    histogram(es, opts.output, opts.title, width, height)
