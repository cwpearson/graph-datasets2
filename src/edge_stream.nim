import streams

import edge

type
    EdgeStream* = ref EdgeStreamObj
    EdgeStreamObj* = object of RootObj
        stream*: Stream
        readEdgeImpl*: proc (s: EdgeStream, edge: var Edge): bool
        writeEdgeImpl*: proc (s: EdgeStream, edge: Edge)


proc readEdge *(s: EdgeStream, edge: var Edge): bool =
    return s.readEdgeImpl(s, edge)

proc writeEdge *(s: EdgeStream, edge: Edge) =
    s.writeEdgeImpl(s, edge)

proc setPosition*(s: EdgeStream, pos: int) =
    s.stream.setPosition(pos)

proc getPosition*(s: EdgeStream): int =
    result = s.stream.getPosition()

proc atEnd*(s: EdgeStream): bool =
    result = s.stream.atEnd()

proc close*(s: EdgeStream) =
    s.stream.close()

iterator edges*(s: EdgeStream): Edge =
    var edge: Edge
    while s.readEdge(edge):
        yield edge

