import streams
import system
import strutils
import sequtils
import algorithm
import os
import sets
import strformat

import ../dict
import ../edge
import ../logger
import ../twitter_dataset
import ../format
import ../delimited
import ../edge_stream
import ../graph_challenge


type
    ConvertError* = object of Exception
    SrcKindUnknownError = object of ConvertError


proc convert*(src: string, dst: string, force: bool, srcKindHint = dkUnknown,
        srcPos = 0, dstPos = 0, weightPos = 0): int {.discardable.} =

    if not force and fileExists(dst) or dirExists(dst):
        error(&"{dst} alread exists")
        quit(1)

    var srcKind = srcKindHint
    if srcKind == dkUnknown:
        srcKind = guessFormat(src)
    let
        dstKind = guessFormat(dst)

    if srcKind == dkUnknown:
        raise newException(SrcKindUnknownError, &"{src}")

    if dstKind == dkUnknown:
        echo "unable to determine format for dst ", src
        quit(1)

    info(&"converting {src} ({srcKind}) to {dst} ({dstKind})")

    ## Convert Twitter -> edge list
    if srcKind == dkTwitter and isEdgeList(dstKind):

        var initialSize = sets.rightSize(3_000_000_000)
        var edges = initHashSet[Edge](initialSize)

        var canonical = initDict[int, int]()

        var nextId = 0

        debug("reading & uniqifying ", src)
        var
            maxrow = low(int)
            maxcol = low(int)
        var twitter = Twitter(path: src)
        for edge in twitter.edges():
            # canonicalize edge ID, and add a bi-directional version of each edge
            let
                user = edge.src
                follower = edge.dst
            if not canonical.hasKeyOrPut(user, nextId):
                nextId += 1
            if not canonical.hasKeyOrPut(follower, nextId):
                nextId += 1
            let
                canonsrc = canonical[user]
                canondst = canonical[follower]
            edges.incl(initEdge(canonsrc, canondst))
            edges.incl(initEdge(canondst, canonsrc))
            maxrow = max(maxrow, canonsrc)
            maxcol = max(maxrow, canondst)
        let nnz = len(edges)

        # Sorting with custom proc
        debug("making sortable...")
        var sortedEdges = toSeq(edges)
        debug("sorting...")
        sort(sortedEdges, graph_challenge.cmp)

        var es = guessEdgeStreamWriter(dst, maxrow+1, maxcol+1, nnz)

        notice("writing ", dst)
        for edge in sortedEdges:
            es.writeEdge(edge)

    elif isEdgeList(srcKind) and isEdgeList(dstKind):

        var srces: EdgeStream
        if srcKind == dkDelimited:
            info(&"reading edge src,dst,weight from cols {srcPos},{dstPos},{weightPos}")
            srces = openDelimitedStream(src, '\t', srcPos, dstPos, weightPos)
        else:
            srces = guessEdgeStreamReader(src, srcKind)

        # for some kinds of outputs, we need to know some info
        var
            maxrows = 0
            maxcols = 0
            entries = 0
        case dstKind
        of dkBmtx, dkMtx:
            info(&"read {src} for matrix dimensions")
            for edge in srces.edges():
                maxrows = max(maxrows, edge.src)
                maxcols = max(maxcols, edge.dst)
                entries += 1
            info(&"got {maxrows+1} rows, {maxcols+1} cols, and {entries} nnz")
        else:
            discard

        var dstes = guessEdgeStreamWriter(dst, maxrows+1, maxcols+1, entries)
        notice(&"{src} -> {dst}")
        for edge in srces.edges():
            dstes.writeEdge(edge)



    else:
        error("don't know how to convert ", srcKind, " to ", dstKind)
        quit(1)

proc doConvert *[T](opts: T) =
    var inputKind: DatasetKind
    case opts.input_kind:
    of $dkUnknown: inputKind = dkUnknown
    of $dkDelimited: inputKind = dkDelimited
    of $dkTsv: inputKind = dkTsv
    of $dkBel: inputKind = dkBel
    of $dkMtx: inputKind = dkMtx
    of $dkBmtx: inputKind = dkBmtx

    let srcPos = parseInt opts.src_pos
    let dstPos = parseInt opts.dst_pos
    let weightPos = parseInt opts.weight_pos

    convert(src = opts.input, dst = opts.output, force = opts.force,
            srcKindHint = inputKind, srcPos = srcPos, dstPos = dstPos,
                    weightPos = weightPos)
