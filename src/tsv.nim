import streams
import strutils

import edge
import edge_stream

type TsvStream* = ref object of EdgeStream
    line: string

method readEdge *(s: TsvStream, edge: var Edge): bool =
    let good = s.stream.readLine(s.line)
    if good:
        let fields: seq[string] = s.line.splitWhitespace()
        edge.src = parseInt fields[0]
        edge.dst = parseInt fields[1]
        edge.weight = parseFloat fields[2]
    good

method writeEdge *(s: TsvStream, edge: Edge) =
    let str = $edge.src & "\t" & $edge.dst & "\t" & $int(edge.weight)
    s.stream.writeLine(str)

proc newTsvStream *(stream: Stream): TsvStream = 
    new(result)
    result.stream = stream

proc openTsvStream *(path: string, mode: FileMode): TsvStream =
    var stream = newFileStream(path, mode)
    result = newTsvStream(stream)

