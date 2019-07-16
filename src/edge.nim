import hashes

type Edge * = object of RootObj
    src*: uint64
    dst*: uint64
    weight*: float64

proc initEdge *(src: uint64, dst: uint64): Edge =
    Edge(src: src, dst: dst, weight: 1.0'f64)

proc hash *(x: Edge): Hash =
    ## Computes a Hash from `x`.
    var h: Hash = 0
    # Iterate over parts of `x`.
    # Mix the atom with the partial hash.
    h = h !& hash(x.src)
    h = h !& hash(x.dst)
    h = h !& hash(x.weight)
    # Finish the hash.
    result = !$h