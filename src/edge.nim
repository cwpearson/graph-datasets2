import hashes

type Edge* = object of RootObj
    src*: int
    dst*: int
    weight*: float64

proc initEdge *(src: int, dst: int, weight: float = 1.0'f64): Edge {.inline, noinit.} =
    result.src = src
    result.dst = dst
    result.weight = weight


proc hash *(x: Edge): Hash =
    ## Computes a Hash from `x`.
    var h: Hash = 0
    h = h !& hash(x.src)
    h = h !& hash(x.dst)
    h = h !& hash(x.weight)
    result = !$h
