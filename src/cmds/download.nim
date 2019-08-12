import strutils
import nre
import strformat
import os
import sequtils

import ../logger
import ../nethelper
import ../datasets


proc download *(dataset: string, dryRun: bool, force: bool,
    format: string, list: bool, name: string, output: string, provider: string
        ) =
    ## download one or more datasets

    if not list:
        if not existsDir(output):
            if dryRun:
                warn(&"would fail: directory {output} does not exist")
            else:
                error(&"directory {output} does not exist")
                quit(1)

    var remaining = allDatasets
    remaining = filter(remaining, nameRegexMatcher(dataset))
    if provider != "":
        remaining = filter(remaining, providerExactMatcher(provider))
    if format != "":
        remaining = filter(remaining, formatExactMatcher(format))


    for dataset in remaining:
        if list:
            echo $dataset
        else:
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
    download(dataset = opts.dataset, dryRun = opts.dry_run, force = opts.force,
            format = opts.format, list = opts.list, name = opts.name,
            output = opts.output, provider = opts.provider)



