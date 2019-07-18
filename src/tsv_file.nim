import edge
import streams
import strutils


type Tsv* = ref object of RootObj
    path*: string
    strm: FileStream
    line: string

method readEdge *(this: Tsv, edge: var Edge): bool {.base.} =
    let good = this.strm.readLine(this.line)
    if good:
        let fields: seq[string] = this.line.splitWhitespace()
        edge.src = parseInt fields[0]
        edge.dst = parseInt fields[1]
        edge.weight = parseFloat fields[2]
    good

method writeEdge *(this: Tsv, edge: Edge): int {.discardable, base.} =
    let srcStr = intToStr(int(edge.src))
    let dstStr = intToStr(int(edge.dst))
    let weightStr = intToStr(int(edge.weight))
    this.strm.writeLine([srcStr, dstStr, weightStr].join("\t"))

method close *(this: Tsv): bool {.discardable, base.} =
    this.strm.close()

proc openTsv *(path: string, mode: FileMode): Tsv =
    var f = Tsv(path: path)
    try:
        echo "opening ", f.path
        f.strm = openFileStream(f.path, mode)
    except:
        raise
    f
