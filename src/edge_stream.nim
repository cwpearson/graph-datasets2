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

iterator edges*(s: EdgeStream): Edge =
    var edge: Edge
    while s.readEdge(edge):
        yield edge