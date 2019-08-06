import strutils
import nre
import strformat
import os
import sequtils

import ../logger
import ../nethelper
import ../datasets


proc download *(dataset, output: string, force: bool = false, dryRun: bool = false) =
    ## download one or more datasets
    ## filter by provider name, dataset name, dataset format, and size
    ## if the name or provider matches exactly, keep only those, otherwise, treat it as a regex
    ## if force,

    if not existsDir(output):
        if dryRun:
            warn(&"would fail: directory {output} does not exist")
        else:
            error(&"directory {output} does not exist")
            quit(1)

    proc matchName(d: Dataset): bool =
        d.name == dataset

    var remaining: seq[Dataset]
    remaining = filter(allDatasets, matchName)
    

    for dataset in remaining:
        # if dataset is already in output, we're done
        if dryRun:
            notice(&"would check if {dataset} already exists")
        else:
            notice(&"checking {dataset}")
            if dataset.verify(output):
                notice(&"{dataset} already exists")
                return

        if dryRun:
            notice(&"would download {dataset}")
        else:
            if not dataset.verifyDownload(output):
                notice(&"downloading {dataset}")
                dataset.download(output)

        if dryRun:
            notice(&"would extract {dataset}")
        else:
            notice(&"extracting {dataset}")
            dataset.extract(output)


proc doDownload *[T](opts: T): int {.discardable.} =
    download(dataset = opts.dataset, output = opts.output, force = opts.force, dryRun = opts.dry_run)



