import os

type DatasetKind * = enum
    dkBel
    dkTsv
    dkTwitter
    dkUnknown

proc guessFormat *(path: string): DatasetKind = 
    let splittedPath = splitPath(path)
    if splittedPath.tail == "twitter_rv.net":
        return dkTwitter

    let splittedFile = splitFile(path)
    if splittedFile.ext == ".bel":
        return dkBel
    elif splittedFile.ext == ".tsv":
        return dkTsv

    return dkUnknown