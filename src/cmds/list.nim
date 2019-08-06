import strformat
import nre
import sequtils

import ../datasets

proc list(provider: string = "", name: string = "", format: string = "",
        full: bool = false) =

    proc filterFunc(d: Dataset): bool =
        result = true
        if result and name != "":
            let regex = re(name)
            result = result and d.name.contains(regex)
        if result and format != "":
            result = result and (d.format == format)

    var remaining: seq[Dataset]

    remaining = filter(allDatasets, filterFunc)

    for dataset in remaining:
        let name = dataset.name
        let desc = dataset.description
        let format = dataset.format
        if full:
            echo &"{dataset}\t{desc}"
        else:
            echo &"{dataset}"


proc doList *[T](opts: T) =
    list(opts.provider, opts.name, opts.format, opts.full)

when isMainModule:
    list(full = true)
