import edge
import streams
import strutils
import os



type Bel * = ref object of RootObj
  path *: string
  strm: FileStream

method readEdge *(this: Bel, edge: var Edge):  bool {.base.} = 
    var buffer: array[3, uint64]
    let good = this.strm.readData(addr(buffer), sizeof(buffer))
    if good == sizeof(buffer):
        edge.src = buffer[0]
        edge.dst = buffer[1]
        edge.weight = float(buffer[2])
        return true
    else:
        if not this.strm.atEnd():
            echo "ERROR reading stream"
            quit(1)
    return false

method writeEdge *(this: Bel, edge: Edge): bool {. discardable, base .} = 
    var buffer = [uint64(edge.src), uint64(edge.dst), uint64(edge.weight)]
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
