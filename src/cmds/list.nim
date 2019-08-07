import strformat
import sequtils

import ../datasets

proc list(provider: string = "", name: string = "", format: string = "",
        full: bool = false) =

    var remaining = allDatasets
    if name != "":
        remaining = filter(remaining, nameRegexMatcher(name))
    if format != "":
        remaining = filter(remaining, formatExactMatcher(format))
    if provider != "":
        remaining = filter(remaining, providerExactMatcher(provider))

    for dataset in remaining:
        let desc = dataset.description
        if full:
            echo &"{dataset}\t{desc}"
        else:
            echo &"{dataset}"


proc doList *[T](opts: T) =
    list(opts.provider, opts.name, opts.format, opts.full)

when isMainModule:
    list(full = true)
