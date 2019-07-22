import edge


type
    CsrPart*[V, E] = object
        ## a partitioned CSR, both along rows and columns
        ## row_part_size: the number of rows in each partition
        ## col_part_size: the size of each column partition
        ##
        part_size: int
        num_parts: int
        row_ptrs: seq[seq[E]]
        col_ind: seq[V]
        max_vert: V

proc initCsrPart*[V, E] (nnz: int, num_rows: int): CsrPart[V, E] =
    ## create a new CsrPart
    ##
    result.num_parts = 6
    result.part_size = num_rows div result.num_parts
    result.row_ptrs = newSeq[seq[E]](result.num_parts+1)
    result.col_ind = newSeqOfCap[V](nnz)

type
    EdgeOrderError* = object of Exception

proc num_rows*[V, E] (t: CsrPart[V, E]): int =
    assert len(t.row_ptrs) >= 2
    for rp in t.row_ptrs:
        assert len(rp) == len(t.row_ptrs[0])
    result = len(t.row_ptrs[0])

proc num_parts*[V, E] (t: CsrPart[V, E]): int =
    result = numparts

proc addEdge*[V, E] (t: var CsrPart[V, E], edge: Edge): int {.discardable.} =
    let
        src = edge.src
        dst = edge.dst

    # make sure the src is not behind the last src
    if src + 1 < num_rows(t):
        raise newException(EdgeOrderError, "edges must be sorted by src,dst")

    # create all rows up to src
    while num_rows(t) <= src:
        for i, _ in t.row_ptrs:
            t.row_ptrs[i].add(len(t.col_ind))

    # if there is a previous non-zero in the row, we should be larger than it
    # if t.row_ptr[src] != len(t.col_ind):
    #     if dst < t.col_ind[^1]:
    #         raise newException(EdgeOrderError, "edges must be sorted by src,dst")

    # add the new non-zero
    t.col_ind.add(dst)

    # all partitions after the one we are in start 1 later
    let edgePart = min((dst div t.part_size) + 1, num_parts(t))
    for i in (edgePart+1)..num_parts(t):
        t.row_ptrs[i][^1] += 1

    t.max_vert = max(src, t.max_vert)
    t.max_vert = max(dst, t.max_vert)

proc finishEdges*[V, E] (t: var CsrPart[V, E]) =
    # make sure rows including max_vert have a beginning
    while t.num_rows() <= t.max_vert:
        for i in 0..<len(t.row_ptrs):
            t.row_ptrs[i].add(len(t.col_ind))

    # add the row_ptr off the end of the array
    # t.row_ptr.add(len(t.col_ind))



proc nnz*[V, E] (t: CsrPart[V, E]): int =
    return len(t.col_ind)

proc row*[V, E] (t: CsrPart[V, E], r: V): seq[V] =
    let
        rowStart = t.row_ptrs[0][r]
        rowStop = t.row_ptrs[^1][r]
    result = t.col_ind[rowStart..<rowStop]

proc row_part*[V, E] (t: CsrPart[V, E], row: V, part: int): seq[V] =
    let
        rowStart = t.row_ptrs[part][row]
        rowStop = t.row_ptrs[part+1][row]
    result = t.col_ind[rowStart..<rowStop]

iterator rows*[V, E] (t: CsrPart[V, E]): seq[V] =
    for r in 0..<numRows(t):
        echo r
        yield t.row(r)

iterator edges*[V, E] (t: CsrPart[V, E]): tuple[src, dst: V] =
    for r in 0..<numRows(t):
        for c in t.row(r):
            yield (src: r, dst: c)

when isMainModule:
    import unittest

    suite "csr suite 1":

        setup:
            var csr = initCsrPart[int, int](1000)

        test "init":
            check:
                nnz(csr) == 0
                numRows(csr) == 0
        test "edge 0->1, 0->10, 1->3":
            let edges = @[initEdge(0, 1), initEdge(0, 10), initEdge(1, 3)]
            for edge in edges:
                csr.addEdge(edge)
            csr.finishEdges()
            check:
                nnz(csr) == 3
                numRows(csr) == 11
                row(csr, 0) == @[1, 10]
                row(csr, 1) == @[3]

        test "edge 3->0, 4->10":
            let edges = @[initEdge(3, 0), initEdge(4, 10)]
            for edge in edges:
                csr.addEdge(edge)
            csr.finishEdges()
            check:
                nnz(csr) == 2
                numRows(csr) == 11


