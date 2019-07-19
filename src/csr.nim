import edge

type
    Csr*[V, E] = object
        row_ptr: seq[E]
        col_ind: seq[V]
        max_vert: V

type
    EdgeOrderError* = object of Exception

proc initCsr*[V,E] (num_rows: int = 0, nnz: int = 0): Csr[V,E] =
    result.row_ptr = newSeqOfCap[E](num_rows+1)
    result.col_ind = newSeqOfCap[V](nnz)

proc addEdge*[V,E] (t: var Csr[V,E], edge: Edge): int {.discardable.} =
    let
        src = edge.src
        dst = edge.dst

    # make sure the src is not behind the last src
    if src + 1 < len(t.row_ptr):
        raise newException(EdgeOrderError, "edges must be sorted by src,dst")

    # finish rows until we reach src
    while len(t.row_ptr) <= src:
        t.row_ptr.add(len(t.col_ind))

    # if there is a previous non-zero in the row, we should be larger than it
    if t.row_ptr[src] != len(t.col_ind):
        if dst < t.col_ind[^1]:
            raise newException(EdgeOrderError, "edges must be sorted by src,dst")

    # add the new non-zero
    t.col_ind.add(dst)

    t.max_vert = max(src, t.max_vert)
    t.max_vert = max(dst, t.max_vert)

proc finishEdges*[V,E] (t: var Csr[V,E]) =
    # make sure rows including max_vert have a beginning
    while len(t.row_ptr) <= t.max_vert:
        t.row_ptr.add(len(t.col_ind))
    
    # add the row_ptr off the end of the array
    t.row_ptr.add(len(t.col_ind))

proc num_rows*[V,E] (t: Csr[V,E]): int =
    if len(t.row_ptr) > 0:
        result = len(t.row_ptr) - 1
    else:
        result = 0

proc nnz*[V,E] (t: Csr[V,E]): int =
    return len(t.col_ind)

proc row*[V,E] (t: Csr[V,E], r: V): seq[V] =
    let 
        rowStart = t.row_ptr[r]
        rowStop = t.row_ptr[r+1]
    result = t.col_ind[rowStart..<rowStop]

iterator rows*[V,E] (t: Csr[V,E]): seq[V] =
    for r in 0..<numRows(t):
        echo r
        yield t.row(r)

iterator edges*[V,E] (t: Csr[V,E]): tuple[src, dst: V] =
    for r in 0..<numRows(t):
        for c in t.row(r):
            yield (src: r, dst: c)

when isMainModule:
    import unittest

    var csr = initCsr[int, int]()
    for row in rows csr:
        discard
    for edge in edges csr:
        discard

    suite "csr suite 1":
    
        setup:
            var csr = initCsr[int, int]()
    
        test "init":
            check:
                nnz(csr) == 0
                numRows(csr) == 0
        test "edge 0->1, 0->10, 1->3":
            let edges = @[initEdge(0,1), initEdge(0,10), initEdge(1,3)]
            for edge in edges:
                csr.addEdge(edge)
            csr.finishEdges()
            check:
                nnz(csr) == 3
                numRows(csr) == 11
                row(csr, 0) == @[1,10]
                row(csr, 1) == @[3]

        test "edge 3->0, 4->10":
            let edges = @[initEdge(3,0), initEdge(4,10)]
            for edge in edges:
                csr.addEdge(edge)
            csr.finishEdges()
            check:
                nnz(csr) == 2
                numRows(csr) == 11


