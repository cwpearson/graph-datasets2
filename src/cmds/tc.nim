import strformat
import times

import ../csr
import ../bel
import ../format
import ../logger
import ../edge
import ../edge_stream


type FilterKind = enum
    fkNone
    fkUpper
    fkLower

proc toSeconds(d: Duration): float =
    result = float(d.inNanoseconds) / 1e9


proc tc (path: string, filter_kind: FilterKind) =
    let datasetKind = guessFormat(path)

    proc lt(edge: Edge): bool {.inline.} =
        return edge.src > edge.dst
    proc ut(edge: Edge): bool {.inline.} =
        return edge.dst < edge.src
    proc full(edge: Edge): bool {.inline.} = true

    let filter = case filter_kind
    of fkLower: lt
    of fkUpper: ut
    of fkNone: full
    case datasetKind
    of dkBel:

        var
            start: Time
            elapsed: Duration
            eps: float

        debug("open ", path)
        let bel = openBelStream(path, fmRead)
        defer: bel.close()

        notice("build CSR")
        start = getTime()
        var csr = initCsr[int, int]()
        for edge in bel.edges():
            if filter(edge):
                csr.addEdge(edge)
        csr.finishEdges()
        elapsed = getTime() - start
        eps = float(nnz(csr)) / elapsed.toSeconds
        info(&"nnz:      {nnz csr}")
        info(&"num rows: {numRows csr}")
        info(&"{elapsed}, {eps:e}")

        notice("count triangles")
        start = getTime()
        var count = 0
        for edge in csr.edges():
            let
                src = edge.src
                dst = edge.dst
                srcRow = csr.row(src)
                dstRow = csr.row(dst)
            var
                ai = 0
                bi = 0
                loadA = true
                loadB = true
                a, b: typeof(srcRow[0])
            while ai < len(srcRow) and bi < len(dstRow):
                if loadA:
                    a = srcRow[ai]
                    loadA = false
                if loadB:
                    b = dstRow[bi]
                    loadB = false
                if a == b:
                    count += 1
                    ai += 1
                    bi += 1
                    loadA = true
                    loadB = true
                elif a < b:
                    ai += 1
                    loadA = true
                else:
                    bi += 1
                    loadB = true
        elapsed = getTime() - start
        eps = float(nnz(csr)) / elapsed.toSeconds
        info(&"{elapsed}, {eps:e}")
        echo count
    else:
        error("ERROR can't count for ", path, " of kind ", datasetKind)
        quit(1)

proc doTc *[T](opts: T): int {.discardable.} =


    var fk: FilterKind
    if opts.filter == "lower":
        fk = fkLower
    elif opts.filter == "upper":
        fk = fkUpper
    else:
        fk = fkNone

    tc(opts.input, fk)

