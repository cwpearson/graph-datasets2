import streams
import system
import strutils
import sequtils
import algorithm
import tables
import os
import sets

import edge
import twitter_dataset
import tsv_file
import bel_file


proc convert *(src: string, dst:string): int {.discardable.} = 

    var 
        srcKind = ""
        dstKind = ""

    let splittedSrc = splitPath(src)
# assert splittedPath.head == "/path/to/my"
    echo splittedSrc.tail
    if srcKind == "" and splittedSrc.tail == "twitter_rv.net":
        srcKind = "twitter"

    let splitted = splitFile(src)
    if splitted.ext == ".bel":
        srcKind = "bel"
    elif splitted.ext == ".tsv":
        srcKind = "tsv"

    if srcKind == "":
        echo "unable to determine format for source ", src
        quit(1)



    let splittedDst = splitFile(dst)
    if splittedDst.ext == ".bel":
        dstKind = "bel"
    elif splittedDst.ext == ".tsv":
        dstKind = "tsv"
    else: 
        echo "unable to determine format for dst ", src
        quit(1)

# assert splittedFile.dir == "/path/to/my"
# assert splittedFile.name == "file"


    echo "converting ", src, " ", srcKind, " to ", dst, " ", dstKind

    if srcKind == "twitter" and ( dstKind == "bel" or dstKind == "tsv"):

        var initialSize = sets.rightSize(3_000_000_000)
        var edges = initHashSet[Edge](initialSize)

        initialSize = tables.rightSize(42_000_000)
        var canonical = initTable[uint64, uint64](initialSize)

        var nextId = 0'u64

        var lineCount = 0'i64

        echo "reading & uniqifying ", src
        var twitter = Twitter(path: src)
        var edge: Edge
        while twitter.readEdge(edge):
            # canonicalize the edge direction, since we will end up generating bidirectional edges
            # this prevents duplicate edges if there is a bidirectional edge in the input graph
            var user = edge.src
            var follower = edge.dst
            if not canonical.hasKeyOrPut(user, nextId):
                nextId += 1
                if canonical.len() %% 1000000 == 0:
                    echo "unique ids ", canonical.len()
            if not canonical.hasKeyOrPut(follower, nextId):
                nextId += 1
                if canonical.len() %% 1000000 == 0:
                    echo "unique ids ", canonical.len()
            var src = canonical[user]
            var dst = canonical[follower]
            edges.incl(newEdge(src, dst))
            edges.incl(newEdge(dst, src))
            lineCount += 1
            if lineCount %% 1000000'i64 == 0:
                echo "line ", lineCount

        # Sorting with custom proc
        echo "making sortable..."
        var sortedEdges = toSeq(edges)

        echo "sorting..."
        sortedEdges.sort do (x, y: Edge) -> int:
            result = cmp(x.dst, y.dst)
            if result == 0:
                result = cmp(x.src, y.src)

        if dstKind == "tsv":
            echo "writing ", dst
            var tsv = openTsv(dst, fmWrite)
            for e in sortedEdges:
                tsv.writeEdge(e)
        elif dstKind == "bel":
            echo "writing ", dst
            var bel = openBel(dst, fmWrite)
            for e in sortedEdges:
                bel.writeEdge(e)
        else:
            echo "unexpected dstKind ", dstKind
            quit(1)

    elif srcKind == "tsv" and dstKind == "bel":
        var
            tsv = openTsv(src, fmRead)
            bel = openBel(dst, fmWrite)
        
        var edge: Edge
        while tsv.readEdge(edge):
            bel.writeEdge(edge)
        tsv.close()
        bel.close()
    elif srcKind == "bel" and dstKind == "tsv":
        var
            tsv = openTsv(src, fmWrite)
            bel = openBel(dst, fmRead)
        
        var edge: Edge
        while bel.readEdge(edge):
            tsv.writeEdge(edge)
        tsv.close()
        bel.close()

    else:
        echo "don't know how to convert ", srcKind, " to ", dstKind


