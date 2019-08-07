import os

proc fullSplitFile*(path: string): tuple[dir, name, ext: string] = 
    ## split filename into (dir, name, ext) tuple
    ## /blah/test.tar.gz -> /blah, test, .tar.gz
    var (dir, name, ext) = splitFile(path)
    while true:
        let newSplit = splitFile(dir / name)
        if newSplit.ext == "":
            break
        ext = newSplit.ext & ext
        name = newSplit.name
    result = (dir, name, ext)