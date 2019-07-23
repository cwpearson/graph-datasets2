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
    notice("open ", path)
    let es = guessEdgeStreamReader(path)

    proc lt(edge: Edge): bool {.inline.} =
        return edge.src > edge.dst
    proc ut(edge: Edge): bool {.inline.} =
        return edge.dst < edge.src
    proc full(edge: Edge): bool {.inline.} = true

    let filter = case filter_kind
    of fkLower: lt
    of fkUpper: ut
    of fkNone: full


    var
        start: Time
        elapsed: Duration
        eps: float




    notice("build CSR")
    start = getTime()
    var csr = initCsr[int, int]()
    for edge in es.edges():
        if filter(edge):
            csr.addEdge(edge)
    csr.finishEdges()
    elapsed = getTime() - start
    eps = float(nnz(csr)) / elapsed.toSeconds
    notice(&"nnz:      {nnz csr}")
    notice(&"num rows: {numRows csr}")
    notice(&"{elapsed}, {eps:e}")

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
    notice(&"{elapsed}, {eps:e}")
    echo count


proc doTc *[T](opts: T): int {.discardable.} =


    var fk: FilterKind
    if opts.filter == "lower":
        fk = fkLower
    elif opts.filter == "upper":
        fk = fkUpper
    else:
        fk = fkNone

    tc(opts.input, fk)

