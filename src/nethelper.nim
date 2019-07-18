import streams
import httpclient
import os
import strformat
import asyncdispatch
import asyncfile

import logger

proc retrieve_url *(url: string, path: string, retries: int = 3): bool =

    var client: AsyncHttpClient = newAsyncHttpClient()
    defer: client.close()

    proc downloadEx(): Future[void] {.async.} =
        var retriesLeft = retries
        while retriesLeft > 0:
            retriesLeft -= 1

            var file: AsyncFile
            var headers = newHttpHeaders()
            debug("looking for ", path)
            if fileExists(path):
                let sz = getFileSize(path)
                debug("partial download, existing file is size ", sz)

                headers = newHttpHeaders({
                    "Range": &"bytes={sz}-"
                })
                file = openAsync(path, fmAppend)
            else:
                file = openAsync(path, fmWrite)

            debug("client.request")
            var response = await client.request(url = url, headers = headers)
            debug("checking response code")
            if response.code.is4xx or response.code.is5xx:
                error("http error: ", response.status)
                if retriesLeft <= 0:
                    raise newException(HttpRequestError, response.status)
                else:
                    debug("retry after 1000ms, ", retriesLeft, " retries left")
                    sleep(1000)
                    continue

            debug("await writeFromtStream")
            await file.writeFromStream(response.bodyStream)
            break



    var res = newFuture[void]("net::retrieve_url")
    try:
        res = downloadEx()
    except Exception as exc:
        res.fail(exc)
        raise
    waitFor res

    return true

