import strutils

import ../logger
import ../nethelper

var sources = @[
        ("graphchallenge/amazon0302", "https://graphchallenge.s3.amazonaws.com/snap/amazon0302/amazon0302_adj.tsv",
                ""),
        ("graphchallenge/amazon0312", "https://graphchallenge.s3.amazonaws.com/snap/amazon0312/amazon0312_adj.tsv",
                ""),
        ("graphchallenge/soc-Epinions", "https://graphchallenge.s3.amazonaws.com/snap/soc-Epinions1/soc-Epinions1_adj.tsv",
                ""),
        ("twitter/twitter_rv", "http://an.kaist.ac.kr/~haewoon/release/twitter_social_graph/twitter_rv.zip",
                ""),
    ]


proc fuzzy_match(a, b: string): int =
    let
        la = toLowerAscii(a)
        lb = toLowerAscii(b)
    return strutils.editDistance(la, lb)

proc download(search_name: string): int {.discardable.} =
    var min_dist = high(int)
    var min_idx = len(sources)
    for i, (name, url, hash) in sources:
        let d = fuzzy_match(name, search_name)
        echo d, " ", name
        if d < min_dist:
            min_dist = d
            min_idx = i
    if min_dist == 0:
        let (name, url, _) = sources[min_idx]
        echo "matched ", name
        discard retrieve_url(url, "test.bel")
        return 0
    else:
        let (name, _, _) = sources[min_idx]
        info("did you mean ", name)
        echo name
        quit(1)





proc doDownload *[T](opts: T): int {.discardable.} =
    download(opts.name)
