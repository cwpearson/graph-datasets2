import edge
import streams
import strutils
import os



type Bel * = ref object of RootObj
  path *: string
  strm: FileStream
  line: string

method readEdge *(this: Bel, edge: var Edge):  bool {.base.} = 
    let good = this.strm.readLine(this.line)
    if good:
        let fields: seq[string] = this.line.splitWhitespace()
        edge.src = parseBiggestUint fields[1]
        edge.dst = parseBiggestUint fields[0]
    good

method writeEdge *(this: Bel, edge: Edge): bool {. discardable, base .} = 
    var buffer = [uint64(edge.dst), uint64(edge.src), uint64(edge.weight)]
    this.strm.writeData(addr(buffer),sizeof(buffer))

method close *(this: Bel): bool {. discardable, base .} =
    this.strm.close()

proc openBel *(path: string, mode: FileMode): Bel  =
    var bel = Bel(path: path)
    try:
        bel.strm = openFileStream(bel.path, mode)
    except:
        stderr.write getCurrentExceptionMsg()
        raise
    bel
