import os
import strformat

# edge stream formats
import edge_stream
import tsv
import bel
import mtx
import bmtx

import logger

type DatasetKind* = enum
    dkBel
    dkTsv
    dkTwitter
    dkBmtx
    dkMtx
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

proc isEdgeList *(dk: DatasetKind): bool =
    case dk
    of dkBel, dkBmtx, dkMtx, dkTsv:
        return true
    of dkTwitter, dkUnknown:
        return false

proc guessEdgeStreamReader *(path: string,
        hint: DatasetKind = dkUnknown): EdgeStream =
    var kind = hint
    if kind == dkUnknown:
        kind = guessFormat(path)
    result = case kind
    of dkBel:
        info(&"opening {path} as BEL file")
        openBelStream(path, fmRead)
    of dkTsv:
        info(&"opening {path} as TSV file")
        openTsvStream(path, fmRead)
    of dkMtx:
        info(&"opening {path} as MTX file")
        openMtxReader(path)
    of dkBMtx:
        info(&"opening {path} as BMTX file")
        openBmtxReader(path)
    else:
        error(&"couldn't guess format for {path}")
        nil

proc guessEdgeStreamWriter *(path: string, rows, cols, entries: int,
        hint: DatasetKind = dkUnknown): EdgeStream =
    var kind = hint
    if kind == dkUnknown:
        kind = guessFormat(path)
    result = case kind
    of dkBel:
        info(&"opening {path} as BEL file")
        openBelStream(path, fmWrite)
    of dkTsv:
        info(&"opening {path} as TSV file")
        openTsvStream(path, fmWrite)
    of dkMtx:
        info(&"opening {path} as MTX file")
        openMtxWriter(path, rows, cols, entries)
    of dkBMtx:
        info(&"opening {path} as BMTX file")
        openBmtxWriter(path, rows, cols, entries)
    else:
        error(&"couldn't guess format for {path}")
        nil

