# type Edge * = tuple[src: uint64, dst: uint64, weight: float64]

type Edge * = object
    src*: uint64
    dst*: uint64
    weight*: float64

proc newEdge *(src: uint64, dst: uint64): Edge =
    Edge(src: src, dst: dst, weight: 1.0'f64)