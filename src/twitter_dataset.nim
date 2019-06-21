import edge
import streams
import strutils
import strscans


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
        var
            src: int
            dst: int
        if scanf(this.line, "$s$i$s$i$s", src, dst):
            edge = newEdge(uint64(src), uint64(dst))
        else:
            echo "error"
            quit(1)
        

    good

method isGood *(this: Twitter): bool {.base.} = 
    isNil(this.istrm)

   