import streams
import strutils
import strscans
import httpclient
import os
import strformat
import asyncdispatch
import asyncfile

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
                defer: file.close()
            else:
                file = openAsync(this.path, fmWrite)
                defer: file.close()

            var response = await client.request(url = url, headers = headers)
            
            await file.writeFromStream(response.bodyStream)

            echo "checking response code"
            if response.code.is4xx or response.code.is5xx:
                echo "http error: ", response.status
                if retriesLeft <= 0:
                    raise newException(HttpRequestError, response.status)

    var res = newFuture[void]("Twitter::download")
    try:
        res = downloadEx()
    except Exception as exc:
        res.fail(exc)
        raise
    waitFor res

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