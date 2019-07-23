import streams
import strutils
import sequtils
import algorithm
import os
import sets
import math

import ../edge
import ../bel
import ../format
import ../logger
import ../dict
import ../edge_stream


proc cacherows (path: string): int {.discardable.} =

    var es: EdgeStream

    let datasetKind = guessFormat(path)

    case datasetKind
    of dkBel:
        info("open ", path)
        es = openBelStream(path, fmRead)
        defer: es.close()
    else:
        error("ERROR can't count for ", path, " of kind ", datasetKind)
        quit(1)

    assert es != nil
    info("determine in/out degrees ", path)
    var deg = initDict[int, tuple[i: int, o: int]]()
    var nnz = 0
    for edgeIdx, edge in es:
        let (i, o) = deg.getOrDefault(edge.src)
        deg[edge.src] = (i, o+1)
        let (i2, o2) = deg.getOrDefault(edge.dst)
        deg[edge.dst] = (i2+1, o2)
        nnz += 1
        if edgeIdx mod (1024 * 1024) == 0:
            debug("edge ", edgeIdx, "...")

    info("sort verts by degree (descending)")
    proc mycmp(x, y: int): int =
        let
            xt = deg[x]
            x_deg = xt.i + xt.o
            yt = deg[y]
            y_deg = yt.i + yt.o
        if x_deg < y_deg:
            return 1
        elif x_deg > y_deg:
            return -1
        return 0

    var srcp = toSeq(deg.keys())
    sort(srcp, mycmp)


    info("cache verts")
    var cacheEntriesRemaining = int(float(nnz) * 0.05)
    info("cache size ", cacheEntriesRemaining, " / ", nnz, "( ", float(
            cacheEntriesRemaining) / float(nnz), "% )")
    var cachedVerts = initDict[int, ()]()

    for v in srcp:
        let (i, o) = deg[v]
        if o == 0:
            # debug("empty ", v, "(", i, " ", o, ")")
            continue
        elif cacheEntriesRemaining >= o:
            debug("cached ", v, "(", i, " ", o, ")")
            cachedVerts[v] = ()
            cacheEntriesRemaining -= o
        elif cacheEntriesRemaining == 0:
            break
        else:
            # debug("skip ", v, "(", i, " ", o, ")")
            continue

    info("cached ", len(cachedVerts), " rows")

    info("simulate triangle counting...")
    var
        accessHit = 0
        accessMiss = 0
        rowHit = 0
        rowMiss = 0
    for edge in edges(es):
        let
            src = edge.src
            dst = edge.dst
        if cachedVerts.hasKey(src):
            rowHit += 1
            accessHit += deg[src].o
        else:
            rowMiss += 1
            accessMiss += deg[src].o
        if cachedVerts.hasKey(dst):
            rowHit += 1
            accessHit += deg[dst].o
        else:
            rowMiss += 1
            accessMiss += deg[dst].o
    echo "row_hits,", rowHit, ",", float(rowHit) / float(rowHit + rowMiss)
    echo "row_miss,", rowMiss, ",", float(rowMiss) / float(rowHit + rowMiss)
    echo "access_hits,", accessHit, ",", float(accessHit) / float(
            accessHit + accessMiss)
    echo "access_miss,", accessMiss, ",", float(accessMiss) / float(
            accessHit + accessMiss)




proc doCacherows *[T](opts: T): int {.discardable.} =
    cacherows(opts.input)

