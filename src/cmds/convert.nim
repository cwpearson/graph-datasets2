import streams
import system
import strutils
import sequtils
import algorithm
import tables
import os
import sets

import ../edge
import ../logger
import ../twitter_dataset
import ../tsv_file
import ../bel_file
import ../format



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

    if srcKind == dkTwitter and (dstKind == dkBel or dstKind == dkTsv):

        var initialSize = sets.rightSize(3_000_000_000)
        var edges = initHashSet[Edge](initialSize)

        initialSize = tables.rightSize(42_000_000)
        var canonical = initTable[uint64, uint64](initialSize)

        var nextId = 0'u64

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
        sort(sortedEdges, bel_file.cmp)

        case dstKind
        of dkTsv:
            debug("writing ", dst)
            var tsv = openTsv(dst, fmWrite)
            for e in sortedEdges:
                tsv.writeEdge(e)
        of dkBel:
            debug("writing ", dst)
            var bel = openBel(dst, fmWrite)
            for e in sortedEdges:
                bel.writeEdge(e)
        else:
            error("unexpected dstKind ", dstKind)
            quit(1)

    elif srcKind == dkTsv and dstKind == dkBel:
        debug(src, " -> ", dst)
        var
            tsv = openTsv(src, fmRead)
            bel = openBel(dst, fmWrite)
        defer: tsv.close()
        defer: bel.close()

        var edge: Edge
        while tsv.readEdge(edge):
            bel.writeEdge(edge)
    elif srcKind == dkBel and dstKind == dkTsv:
        var
            bel = openBel(src, fmRead)
            tsv = openTsv(dst, fmWrite)

        var edge: Edge
        while bel.readEdge(edge):
            tsv.writeEdge(edge)
        tsv.close()
        bel.close()

    else:
        error("don't know how to convert ", srcKind, " to ", dstKind)
        quit(1)

proc doConvert *[T](opts: T): int {.discardable.} =
    convert(opts.input, opts.output)
