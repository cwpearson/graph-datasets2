import unittest

import streams

import tsv, edge

suite "test tsv":

    test "read":
        var IS = newStringStream("""1 2 3
        4 5 6""")
        var IT = newTsvStream(IS)

        var edge: Edge
        discard IT.readEdge(edge)
        check edge == Edge(src: 2, dst: 1, weight: 3.0)
        discard IT.readEdge(edge)
        check edge == Edge(src: 5, dst: 4, weight: 6.0)

        test "read":
            var IS = newStringStream()
            var IT = newTsvStream(IS)

            IT.writeEdge(Edge(src: 2, dst: 1, weight: 3.0))
            IT.writeEdge(Edge(src: 5, dst: 4, weight: 6.0))
            check IS.data == "1\t2\t3\n4\t5\t6\n"
