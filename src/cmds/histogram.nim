import plotly
import sequtils
import strutils
import strformat

import ../format
import ../edge_stream
import ../edge

import ../logger

proc histogram(es: EdgeStream, output, title: string, width, height: int) =



    notice(&"finding largest node")
    var maxNode = 0
    for edge in edges(es):
        maxNode = max(edge.src, maxNode)
        maxNode = max(edge.dst, maxNode)
    info(&"maxNode was {maxNode}")

    # track nodes that actually have degree 0.
    # not all nodes between 0 and maxNode+1 may actually exist
    var nodeExists = newSeq[bool](maxNode+1)
    var degrees = newSeq[int](maxNode+1)

    notice(&"counting degrees")
    for edge in edges(es):
        degrees[edge.src] += 1
        nodeExists[edge.src] = true
        nodeExists[edge.dst] = true

    var compactDegrees = newSeq[int]()
    for exists, degree in items(zip(nodeExists, degrees)):
        if exists:
            compactDegrees.add(degree)

    let d = Trace[int](`type`: PlotType.Histogram)
    # using ys will make a horizontal bar plot
    # using xs will make a vertical.
    d.xs = compactDegrees

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
    when not defined(webview):
        warn("histogram may not work without webview")
    var es = guessEdgeStreamReader(opts.input)
    let
        width = parseInt opts.width
        height = parseInt opts.height
    histogram(es, opts.output, opts.title, width, height)
