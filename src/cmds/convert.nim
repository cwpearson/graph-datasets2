import streams
import system
import strutils
import sequtils
import algorithm
import tables
import os
import sets
import strformat

import ../edge
import ../logger
import ../twitter_dataset
import ../tsv
import ../bel
import ../format
import ../bmtx
import ../mtx
import ../edge_stream
import ../graph_challenge



proc convert (src: string, dst: string): int {.discardable.} =

    let
        srcKind = guessFormat(src)
        dstKind = guessFormat(dst)

    if srcKind == dkUnknown:
        error("unable to determine format for source ", src)
        quit(1)

    if dstKind == dkUnknown:
        echo "unable to determine format for dst ", src
        quit(1)

    info("converting ", src, " ", srcKind, " to ", dst, " ", dstKind)


    if srcKind == dkTwitter and isEdgeList(dstKind):

        var initialSize = sets.rightSize(3_000_000_000)
        var edges = initHashSet[Edge](initialSize)

        initialSize = tables.rightSize(42_000_000)
        var canonical = initTable[int, int](initialSize)

        var nextId = 0

        debug("reading & uniqifying ", src)
        var twitter = Twitter(path: src)
        for edge in twitter.edges():
            # canonicalize the edge direction, since we will end up generating bidirectional edges
            # this prevents duplicate edges if there is a bidirectional edge in the input graph
            let user = edge.src
            let follower = edge.dst
            if not canonical.hasKeyOrPut(user, nextId):
                nextId += 1
            if not canonical.hasKeyOrPut(follower, nextId):
                nextId += 1
            let src = canonical[user]
            let dst = canonical[follower]
            edges.incl(initEdge(src, dst))
            edges.incl(initEdge(dst, src))

        # Sorting with custom proc
        debug("making sortable...")
        var sortedEdges = toSeq(edges)
        debug("sorting...")
        sort(sortedEdges, graph_challenge.cmp)

        var es = case dstKind
        of dkTsv:
            openTsvStream(dst, fmWrite)
        of dkBel:
            openBelStream(dst, fmWrite)
        # of dkBmtx:
            # openBmtxWriter(dst)
        # of dkMtx:
            # openMtxWriter(dst)
        else:
            error("unexpected dstKind ", dstKind)
            quit(1)

        notice("writing ", dst)
        for edge in sortedEdges:
            es.writeEdge(edge)

    elif srcKind == dkTsv and dstKind == dkBel:
        debug(src, " -> ", dst)
        var
            tsv = openTsvStream(src, fmRead)
            bel = openBelStream(dst, fmWrite)
        defer: tsv.close()
        defer: bel.close()

        var edge: Edge
        while tsv.readEdge(edge):
            bel.writeEdge(edge)
    elif srcKind == dkBel and dstKind == dkTsv:
        var
            bel = openBelStream(src, fmRead)
            tsv = openTsvStream(dst, fmWrite)
        defer: tsv.close()
        defer: bel.close()

        for edge in bel.edges():
            tsv.writeEdge(edge)

    elif srcKind == dkBel and (dstKind == dkMtx or dstKind == dkBmtx):
        var
            bel = openBelStream(src, fmRead)

        # read bel file to find entries, rows, and cols
        var
            nnz = 0
            rows = low(int)
            cols = low(int)
        info(&"read {src} for matrix dimensions")
        for edge in bel.edges():
            rows = max(rows, edge.src)
            cols = max(cols, edge.dst)
            nnz += 1
        info(&"got {rows+1} rows, {cols+1} cols, and {nnz} nnz")

        var ostream = newFileStream(dst, fmWrite)
        var es: EdgeStream

        info(&"copy to {dstKind}")
        if dstKind == dkMtx:
            es = newMtxWriter(ostream, rows+1, cols+1, nnz)
        elif dstKind == dkBmtx:
            es = newBmtxWriter(ostream, rows+1, cols+1, nnz)
        else:
            error(&"unexpected dst kind {dstKind}")

        for edge in bel.edges():
            es.writeEdge(edge)

        bel.close()
        ostream.close()

    else:
        error("don't know how to convert ", srcKind, " to ", dstKind)
        quit(1)

proc doConvert *[T](opts: T): int {.discardable.} =
    convert(opts.input, opts.output)
