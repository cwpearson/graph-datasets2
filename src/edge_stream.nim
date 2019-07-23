import streams

import edge

type
    EdgeStream* = ref object of RootObj
        stream*: Stream

method readEdge* (s: EdgeStream, edge: var Edge): bool {.base.} = 
    quit "to be overridden"

method writeEdge* (s: EdgeStream, edge: Edge) {.base.}=
    quit "to be overridden"

method atEnd* (s: EdgeStream): bool {.base.} = 
    result = s.stream.atEnd()

method getPosition* (s: EdgeStream): int {.base.} = 
    result = s.stream.getPosition() 

method setPosition* (s: EdgeStream, pos: int) {.base.} = 
    s.stream.setPosition(pos) 

method close* (s: EdgeStream) {.base.} = 
    s.stream.close()

iterator edges*(s: EdgeStream): Edge =
    s.setPosition(0)
    var edge: Edge
    while s.readEdge(edge):
        yield edge

iterator pairs*(s: EdgeStream): (int, Edge) =
    var cnt = 0
    for edge in s.edges():
        yield (cnt, edge)
        cnt += 1