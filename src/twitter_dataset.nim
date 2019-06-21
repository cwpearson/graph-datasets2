import edge
import streams
import strutils
import strscans
import httpClient


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

method download *(this: Twitter, retries: int = 3 ): bool {. base .} =
    let url = "http://an.kaist.ac.kr/~haewoon/release/twitter_social_graph/twitter_rv.zip"
    
    var client = newHttpClient()

    var onProgressChanged = proc (total, progress, speed: BiggestInt) =
        echo("Downloaded ", progress, " of ", total)
        echo("Current rate: ", speed div 1000, "kb/s")
      
    client.onProgressChanged = onProgressChanged

    var retriesLeft = retries
    while retriesLeft > 0:
        client.downloadFile(url, this.path)

    true
