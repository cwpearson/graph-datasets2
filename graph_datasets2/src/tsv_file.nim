import edge
import streams
import strutils


type Tsv * = ref object of RootObj
  path *: string
  istrm: FileStream
  line: string

method readEdge *(this: Tsv, edge: var Edge):  bool {.base.} = 
    if isNil(this.istrm):
        try:
            this.istrm = openFileStream(this.path, fmRead)
        except:
            stderr.write getCurrentExceptionMsg()
            raise
    let good = this.istrm.readLine(this.line)
    if good:
        let fields: seq[string] = this.line.splitWhitespace()
        edge.src = parseBiggestUint fields[1]
        edge.dst = parseBiggestUint fields[0]
    good

method writeEdge *(this: Tsv, edge: var Edge): int {. base .} = 
    if isNil(this.istrm):
        try:
            this.istrm = openFileStream(this.path, fmWrite)
        except:
            stderr.write getCurrentExceptionMsg()
    let srcStr = ""
    let dstStr = ""
    let weightStr = ""
    this.istrm.writeLine([srcStr, dstStr, weightStr].join("\t"))

method isGood *(this: Tsv): bool {.base.} = 
    isNil(this.istrm)

