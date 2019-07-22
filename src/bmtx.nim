# Reader for the matrix market exchange coodinate format

import edge
import streams
import strutils
import strscans
import strformat

import logger


type
    Bmtx* = object of RootObj
        rows: int
        cols: int
        entries: int
        stream: Stream
    BmtxReader* = object of Bmtx
        line: string
    BmtxWriter* = object of Bmtx
        entries_written: int

proc writeHeader (t: var BmtxWriter) =
    let buf = [int64(t.rows), int64(t.cols), int64(t.entries)]
    t.stream.write(buf)

proc initBmtxWriter *(stream: Stream, rows, cols, entries: int): BmtxWriter =
    result.stream = stream
    result.rows = rows
    result.cols = cols
    result.entries = entries
    result.entries_written = 0
    result.writeHeader()


proc writeEdge *(t: var BmtxWriter, edge: Edge) =
    let
        src = edge.src + 1
        dst = edge.dst + 1
        weight = edge.weight
    debug(&"writing edge {edge} src:{src} dst:{dst} weight:{weight}")
    assert src <= t.rows, &"src {src} should be less than rows {t.rows}"
    assert dst <= t.cols
    assert t.entries_written < t.entries
    t.stream.write(int64(src))
    t.stream.write(int64(dst))
    t.stream.write(float64(weight))
    t.entries_written += 1

proc initBmtxReader *(stream: Stream): BmtxReader =
    result.stream = stream

    # read the header
    var buf: array[3, int64]
    result.stream.read(buf)
    result.rows = int(buf[0])
    result.cols = int(buf[1])
    result.entries = int(buf[2])

    debug(&"bmtx header: {result.rows} rows {result.cols} cols {result.entries} entries")


iterator edges*(t: BmtxReader): Edge =
    # start reading after the header
    t.stream.setPosition(24)

    var buf: tuple[src: int64, dst: int64, weight: float64]

    while not t.stream.atEnd():
        t.stream.read(buf)
        let
            (src, dst, weight) = buf
        if src > t.rows:
            warn(&"binary mtx file has a src {src} > rows {t.rows}")
        yield initEdge(int(src) - 1, int(dst) - 1, float(weight))

when isMainModule:
    var ostream = newStringStream()
    var writer = initBmtxWriter(ostream, 2, 3, 2)
    writer.writeEdge(initEdge(0, 1, 2.0))
    writer.writeEdge(initEdge(1, 2, -1.0))

    var istream = newStringStream(ostream.data)
    var reader = initBmtxReader(istream)
    for edge in reader.edges():
        echo edge

