import os

type DatasetKind* = enum
    dkBel
    dkTsv
    dkTwitter
    dkBmtx
    dkmtx
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
    elif splittedFile.ext == ".bmtx":
        return dkBmtx
    elif splittedFile.ext == ".mtx":
        return dkMtx

    return dkUnknown
