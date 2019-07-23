import edge

proc cmp*(x,y: Edge): int {.noinit.} =
    if x.src < y.src:
        return -1
    elif x.src > y.src:
        return 1
    else:
        if x.dst < y.dst:
            return -1
        elif x.dst > y.dst:
            return 1
    return 0