import edge
import streams
import strutils


type Twitter * = ref object of RootObj
  path *: string
  istrm: FileStream
  line: string

method readEdge *(this: Twitter, edge: var Edge):  bool {.base.} = 
    if isNil(this.istrm):
        try:
            this.istrm = openFileStream(this.path, fmRead, 65536)
        except:
            stderr.write getCurrentExceptionMsg()
    let good = this.istrm.readLine(this.line)
    if good:
        let fields: seq[string] = this.line.splitWhitespace()
        let src = parseBiggestUint fields[0]
        let dst = parseBiggestUint fields[1]
        edge = newEdge(src, dst)

    good

method isGood *(this: Twitter): bool {.base.} = 
    isNil(this.istrm)

   