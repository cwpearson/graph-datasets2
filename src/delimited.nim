import streams
import strutils
import strformat

import edge
import edge_stream
import dict
import logger

type DelimitedStream* = ref object of EdgeStream
    line: string
    fieldDelim: char
    srcPos: int
    dstPos: int
    weightPos: int
    ids: Dict[string, int]
    nextId: int

method readEdge *(s: DelimitedStream, edge: var Edge): bool =
    result = s.stream.readLine(s.line)
    if result:
        debug(&"{s.line}")
        let fields: seq[string] = split(s.line, s.fieldDelim)
        debug(&"{fields}")

        let
            srcStr = fields[s.srcPos]
            dstStr = fields[s.dstPos]
            weightStr = fields[s.weightPos]

        if not s.ids.hasKey(srcStr):
            s.ids[srcStr] = s.nextId
            s.nextId += 1
        if not s.ids.hasKey(dstStr):
            s.ids[dstStr] = s.nextId
            s.nextId += 1
        let src = s.ids[srcStr]
        let dst = s.ids[dstStr]
        let weight = parseFloat weightStr
        edge = initEdge(src, dst, weight)
        debug(&"{edge}")

method writeEdge *(s: DelimitedStream, edge: Edge) =
    let str = $edge.dst & "\t" & $edge.src & "\t" & $int(edge.weight)
    s.stream.writeLine(str)

proc newDelimitedStream *(stream: Stream, fieldDelim: char, srcPos,
        dstPos, weightPos: int): DelimitedStream =
    new(result)
    result.stream = stream
    result.fieldDelim = fieldDelim
    result.srcPos = srcPos
    result.dstPos = dstPos
    result.weightPos = weightPos
    result.ids = initDict[string, int]()
    result.nextId = 0

proc openDelimitedStream *(path: string, fieldDelim: char, srcPos, dstPos,
        weightPos: int): DelimitedStream =
    var stream = newFileStream(path, fmRead)
    result = newDelimitedStream(stream, fieldDelim, srcPos, dstPos, weightPos)

