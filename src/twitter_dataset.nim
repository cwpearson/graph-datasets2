import streams
import strutils
import strscans
import httpClient

import logger
import edge

type Twitter * = ref object of RootObj
  path *: string
  strm: FileStream
  line: string

iterator edges *(this: Twitter): Edge =
    this.strm.setPosition(0)
    var line: string
    
    while this.strm.readLine(line):
        var src, dst: int
        if scanf(line, "$s$i$s$i$s", src, dst):
            yield initEdge(uint64(src), uint64(dst))
        else:
            error("error parsing ", line)
            quit(1)


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
