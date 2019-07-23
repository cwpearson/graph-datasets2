import streams
import strutils

import edge
import edge_stream
import logger

type BelStream* = ref object of EdgeStream

method readEdge *(s: BelStream, edge: var Edge): bool =
    var buffer: array[3, uint64]
    let good = s.stream.readData(addr(buffer), sizeof(buffer))
    if good == sizeof(buffer):
        edge.src = int(buffer[1])
        edge.dst = int(buffer[0])
        edge.weight = float(buffer[2])
        return true
    else:
        if not s.atEnd():
            error("couldn't read edge from bel")
            quit(1)
    return false


method writeEdge *(s: BelStream, edge: Edge) {.noinit.} =
    let buffer = [uint64(edge.dst), uint64(edge.src), uint64(edge.weight)]
    s.stream.write(buffer)

proc newBelStream* (stream: Stream): BelStream =
    new(result)
    result.stream = stream

proc openBelStream *(path: string, mode: FileMode): BelStream =
    var stream = openFileStream(path, mode)
    result = newBelStream(stream)


