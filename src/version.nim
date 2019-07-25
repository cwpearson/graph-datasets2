import strutils

proc author(nimble: string): string = 
    for line in nimble.splitLines():
        if line.strip().startsWith("author"):
            result = line.split("=")[1].strip(chars = {' ', '"'})
            break

const 
    GdGitSha* : string = staticExec("git rev-parse HEAD")
    GdVerStr* : string = staticExec("git describe --tags HEAD")
    GdAuthor* : string = staticRead("../graph_datasets2.nimble").author()
