import streams
import httpclient
import os
import strformat
import asyncdispatch
import asyncfile
import tables
import strutils
import strformat
import uri

import logger

type RetrieveError* = object of Exception

proc getUrlTail*(url: string): string =
    var uri = initUri()
    parseUri(url, uri)
    let splittedPath = splitPath(uri.path)
    result = splittedPath.tail

proc getUrlSize *(url: string): int =
    ## get the size of a URL, or -1 if unable
    debug(&"request remote size for {url}")
    let client = newHttpClient()
    let response = client.request(url)
    debug(&"got {response.headers.table}")
    if "content-length" in response.headers.table:
        let rawLength = response.headers.table["content-length"][0]
        result = parseInt(rawLength)
    else:
        result = -1

proc retrieveUrl *(url: string, path: string, retries: int = 3, md5 = "") =
    ## download the contents of `url` and place it in a file at `path`
    ##
    ## if the path already exists, and the host supports ranges, download the file until it is the right size
    ## if an md5 is provided, check the hash matches
    ## if the hash fails, retry the whole download

    if url == "":
        let err = &"cannot retrieve url: \"{url}\""
        error(err)
        raise newException(RetrieveError, err)

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
                info("existing file is size ", sz)

                let remoteSz = getUrlSize(url)
                info("remote size is ", remoteSz)

                if sz < remoteSz:
                    info("partial download resuming")
                    headers = newHttpHeaders({
                        "Range": &"bytes={sz}-"
                    })
                    file = openAsync(path, fmAppend)
                elif sz > remoteSz:
                    warn("local file is too big. overwriting")
                    file = openAsync(path, fmWrite)
                else:
                    # no download needed
                    break
            else: # file missing
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

            debug("await writeFromStream")
            await file.writeFromStream(response.bodyStream)
            break



    var res = newFuture[void]("net::retrieve_url")
    try:
        res = downloadEx()
    except Exception as exc:
        res.fail(exc)
        raise
    waitFor res

