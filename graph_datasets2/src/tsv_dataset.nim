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
    let good = this.istrm.readLine(this.line)
    if good:
        let fields: seq[string] = this.line.splitWhitespace()
        edge.src = parseBiggestUint fields[1]
        edge.dst = parseBiggestUint fields[0]
    good

method isGood *(this: Twitter): bool {.base.} = 
    isNil(this.istrm)
