import streams
import strutils
import strscans
import httpclient
import os
import strformat
import asyncdispatch
import asyncfile

import edge

type Twitter * = ref object of RootObj
  path *: string
  strm: FileStream
  line: string

method readEdge *(this: Twitter, edge: var Edge):  bool {.base.} = 
    if isNil(this.strm):
        try:
            this.strm = openFileStream(this.path, fmRead, 65536)
        except:
            stderr.write getCurrentExceptionMsg()
    let good = this.strm.readLine(this.line)
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
    isNil(this.strm)



method download *(this: Twitter, retries: int = 3 ): bool {. base .} =
    ## Downloads twitter and saves it to ``Twitter.path``
    let url = "http://an.kaist.ac.kr/~haewoon/release/twitter_social_graph/twitter_rv.zip"
    
    var client: AsyncHttpClient = newAsyncHttpClient()

    proc downloadEx(): Future[void] {.async.} =

        var retriesLeft = retries
        while retriesLeft > 0:
            retriesLeft -= 1

            var file: AsyncFile
            var headers = newHttpHeaders()

            if fileExists(this.path):
                let sz = getFileSize(this.path)
                echo "partial download, existing file is size ", sz
                headers = newHttpHeaders({
                    "Range": &"bytes={sz}-"
                })
                file = openAsync(this.path, fmAppend)
            else:
                file = openAsync(this.path, fmWrite)

            var response = await client.request(url = url, headers = headers)
            
            await file.writeFromStream(response.bodyStream)

            file.close()

            echo "checking response code"
            if response.code.is4xx or response.code.is5xx:
                echo "http error: ", response.status
                if retriesLeft <= 0:
                    raise newException(HttpRequestError, response.status)

    var result = newFuture[void]("Twitter::download")
    try:
        result = downloadEx()
    except Exception as exc:
        result.fail(exc)
        raise
    waitFor result

    return true


when isMainModule:
    var t = Twitter(path: "twitter.tmp")
    assert t.download()


discard """
proc downloadFile*(client: AsyncHttpClient, url: string,
                   filename: string): Future[void] =
  proc downloadFileEx(client: AsyncHttpClient,
                      url, filename: string): Future[void] {.async.} =
    ## Downloads ``url`` and saves it to ``filename``.
    client.getBody = false
    let resp = await client.get(url)

    client.bodyStream = newFutureStream[string]("downloadFile")
    var file = openAsync(filename, fmWrite)
    # Let `parseBody` write response data into client.bodyStream in the
    # background.
    asyncCheck parseBody(client, resp.headers, resp.version)
    # The `writeFromStream` proc will complete once all the data in the
    # `bodyStream` has been written to the file.
    await file.writeFromStream(client.bodyStream)
    file.close()

    if resp.code.is4xx or resp.code.is5xx:
      raise newException(HttpRequestError, resp.status)

  result = newFuture[void]("downloadFile")
  try:
    result = downloadFileEx(client, url, filename)
  except Exception as exc:
    result.fail(exc)
  finally:
    result.addCallback(
      proc () = client.getBody = true
)
"""