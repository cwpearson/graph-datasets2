import os
import strutils
import strformat

import zip/gzipfiles

import logger

proc getExtractedSize* (path: string): int = 
    ## return extracted size mod 2^32
    var f = open(path, fmRead)
    f.setFilePos(f.getFileSize() - 4)
    var buf: array[4, uint8]
    let bytes = f.readBuffer(addr(buf[0]), len(buf))
    f.close()
    if bytes != 4:
        error("error reading")
        quit(1)
    return int(buf[0]) + (int(buf[1]) shl 8) + (int(buf[2]) shl 16) + (int(buf[3]) shl 24)

proc pathWithoutGz*(path: string): string =
    ## return path without .gz on the end
    let pos = path.rfind(".gz")
    if pos >= 0:
        result = path[0..<pos]
    else:
        result = path

proc extractGz*(src: string, dst: string ="") =
    let extractPath = if dst == "":
        pathWithoutGz(src)
    else:
        dst
    debug(&"extract {src} -> {extractPath}")

    assert extractPath != src

    var s = newGzFileStream(src)
    var w = newFileStream(extractPath, fmWrite)
    var buffer: array[256, uint8]
    while true:
        let bytes = s.readData(buffer[0].addr, buffer.len)
        w.writeData(buffer[0].addr, bytes)
        if bytes < buffer.len:
            break
    s.close()
    w.close()

when isMainModule:
    assert pathWithoutGz("hello.gz") == "hello"
    assert pathWithoutGz("hello.g") == "hello.g"
    assert pathWithoutGz("hello.tar.gz") == "hello.tar"
    assert pathWithoutGz("") == ""
