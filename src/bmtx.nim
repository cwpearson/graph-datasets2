import streams
import strutils
import strscans
import strformat

import edge
import logger
import edge_stream

type
    BmtxStream* = ref object of EdgeStream
        rows: int
        cols: int
        entries: int
        entries_written: int

method readEdge(s: BmtxStream, edge: var Edge): bool =
    if s.getPosition() < 24:
        s.setPosition(24)
    var buf: tuple[src: int64, dst: int64, weight: float64]

    if s.atEnd():
        return false
    else:
        s.stream.read(buf)
        let
            (src, dst, weight) = buf
        let maxrows = s.rows
        if src > maxrows:
            warn(&"binary mtx file has a src {src} > rows {maxrows}")
        edge = initEdge(int(src) - 1, int(dst) - 1, float(weight))
        return true



method writeEdge(s: BmtxStream, edge: Edge) =
    let
        src = edge.src + 1
        dst = edge.dst + 1
        weight = edge.weight
    debug(&"writing edge {edge} -> src:{src} dst:{dst} weight:{weight}")
    assert src <= s.rows, &"src {src} should be less than rows {s.rows}"
    assert dst <= s.cols
    assert s.entries_written < s.entries
    s.stream.write((int64(src), int64(dst), float64(weight)))
    s.entries_written += 1

proc newBmtxStream(stream: Stream): BmtxStream =
    new(result)
    result.stream = stream

proc writeHeader (t: var BmtxStream) =
    let buf = [int64(t.rows), int64(t.cols), int64(t.entries)]
    t.stream.write(buf)

proc newBmtxWriter *(stream: Stream, rows, cols, entries: int): BmtxStream =
    result = newBmtxStream(stream)
    result.rows = rows
    result.cols = cols
    result.entries = entries
    result.writeHeader()
    result.entries_written = 0


proc newBmtxReader *(stream: Stream): BmtxStream =
    result = newBmtxStream(stream)
    # read the header
    var buf: array[3, int64]
    result.stream.read(buf)
    result.rows = int(buf[0])
    result.cols = int(buf[1])
    result.entries = int(buf[2])

    debug(&"read bmtx header: {result.rows} rows {result.cols} cols {result.entries} entries")


when isMainModule:
    var ostream = newStringStream()
    var writer = newBmtxWriter(ostream, 2, 3, 2)
    writer.writeEdge(initEdge(0, 1, 2.0))
    writer.writeEdge(initEdge(1, 2, -1.0))

    var istream = newStringStream(ostream.data)
    var reader = newBmtxReader(istream)
    for edge in reader.edges():
        echo edge
