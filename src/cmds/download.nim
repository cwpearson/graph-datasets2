import strutils
import nre
import strformat
import os

import ../logger
import ../nethelper
import ../datasets

proc fuzzy_match(a, b: string): int =
    let
        la = toLowerAscii(a)
        lb = toLowerAscii(b)
    return strutils.editDistance(la, lb)



proc download *(dataset, output: string, force: bool = false) =
    ## download one or more datasets
    ## filter by provider name, dataset name, dataset format, and size
    ## if the name or provider matches exactly, keep only those, otherwise, treat it as a regex
    ## if force,

    if existsFile(output):
        let logstr = &"file {output} already exists"
        if force:
            warn(logstr)
        else:
            error(logstr)
            quit(1)
    if existsDir(output):
        let logstr = &"dir {output} already exists"
        if force:
            warn(logstr)
        else:
            error(logstr)
            quit(1)


    proc filter(d: Dataset): bool =
        d.name == dataset

    proc filter(p: Provider): bool =
        true

    for (provider, dataset) in filterAll(filter, filter):
        notice(&"downloading {dataset} -> {output}")
        dataset.getter(output)


proc doDownload *[T](opts: T): int {.discardable.} =
    download(dataset = opts.dataset, output = opts.output, force = opts.force)



