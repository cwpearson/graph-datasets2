import strformat
import nre

import ../datasets

proc list(provider: string = "", name: string = "", format: string = "",
        full: bool = false) =

    proc filter(d: Dataset): bool =
        result = true
        if result and name != "":
            let regex = re(name)
            result = result and d.name.contains(regex)
        if result and format != "":
            result = result and (d.format == format)

    proc filter(p: Provider): bool =
        if provider != "":
            let regex = re(provider)
            return p.name.contains(regex)
        return true

    for (provider, dataset) in filterAll(filter, filter):
        let url = dataset.resources[0].url
        let size = dataset.resources[0].size
        let name = dataset.name
        let desc = dataset.description
        let format = dataset.format
        if full:
            echo &"{provider.name}/{name}\t{format}\t{size}\t{url}\t{desc}"
        else:
            echo &"{provider.name}/{name}"


proc doList *[T](opts: T) =
    list(opts.provider, opts.name, opts.format, opts.full)

when isMainModule:
    list(full = true)
