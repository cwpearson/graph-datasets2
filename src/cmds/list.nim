import strformat

import ../datasets

proc list(name: string, full: bool = false) =

    for provider in allProviders:
        for dataset in provider.datasets:
            let url = dataset.resources[0].url
            let size = dataset.resources[0].size
            let name = dataset.name
            if full:
                echo &"{name}\t{size}\t{url}"
            else:
                echo &"{name}"

proc doList *[T](opts: T) =
    list(opts.name, opts.full)

when isMainModule:
    list("")
