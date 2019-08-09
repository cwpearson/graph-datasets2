import unittest

import streams

import mtx, edge, init, logger

suite "test mtx":
    init()
    setLevel(lvlDebug)

    test "read/write matches":

        let someEdges = @[
            Edge(src: 0, dst: 1, weight: 2.0),
            Edge(src: 1, dst: 2, weight: 3.0),
        ]

        var os = newStringStream()
        var writer = newMtxWriter(os, 2, 3, 2)
        for edge in someEdges:
            writer.writeEdge(edge)

        var reader = newMtxReader(newStringStream(os.data))
        check reader.rows == 2
        check reader.cols == 3
        check reader.entries == 2
        check reader.entryKind == ekReal
        check reader.symmetryKind == skGeneral

        var
            edge: Edge
            cnt: int = 0
        while reader.readEdge(edge):
            check edge == someEdges[cnt]
            cnt += 1

