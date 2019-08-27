# graph-datasets2

master: [![Build Status](https://travis-ci.org/cwpearson/graph-datasets2.svg?branch=master)](https://travis-ci.org/cwpearson/graph-datasets2)

develop: [![Build Status](https://travis-ci.org/cwpearson/graph-datasets2.svg?branch=develop)](https://travis-ci.org/cwpearson/graph-datasets2)

Manage a variety of graph datasets

Download [the latest release](https://github.com/cwpearson/graph-datasets2/releases/latest) for your platform.

## Quick Start

* Conversion between multiple formats
* Resumable downloads (for large datasets)
* Some statistics on a variety of datasets

## `graph_datasets download`

Download and extract datasets.

* `graph_datasets download --list`: List all datasets.
* `graph_datasets download --list name`: Show datasets matching regex `name`.
* `graph_datasets download name --format tsv`: Download datasets matching regex `name` with format `tsv`.
* `graph_datasets download GraphChallengeStatic/graph500-scale18-ef16_inc/tsv`: Download this specific datasets


## `graph_datasets convert`

| format | type | signal | desc |
|-|-|-|-|
| GraphChallenge TSV | file | `.tsv` extension | [tsv](https://github.com/cwpearson/graph-datasets2#tsv) |
| BEL | file | `.bel` extension | [bel](https://github.com/cwpearson/graph-datasets2#bel)
| Matrix Market Coordinate | file | `.mtx` extension | [nist](https://math.nist.gov/MatrixMarket/formats.html)
| Binary Matrix Market Coordinate | file | `.bmtx` extension | [bmtx](https://github.com/cwpearson/graph-datasets2#bmtx)
| Twitter | file | `twitter_rv.zip` | [twitter](https://github.com/cwpearson/graph-datasets2#twitter)

* `graph_datasets convert a.tsv b.bmtx`: convert `a` from GraphChallenge tsv to binary matrix-market format.



## Building

Install the latest stable version of nim, then

```
nimble build
./graph_datasets --help
./tc --help
```

Optionally, `-d:webview` can be added to use the system webview instead of the default browser for the histogram plot.
`-d:release` can be added to improve performance.

## Complete

- [x] statistics of datasets
- [x] orient graphs
  - [x] lower triangular
  - [x] upper triangular
  - [x] degree-ordered
- [x] relabeling of vertex IDs
  - [x] graph compaction from Bisson & Fatica [Update on Static Graph Challenge on GPUs](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=8547514) (2018)
- [x] Convert between file formats
  - [x] graph challenge tab-separated values
    - [x] binary version
  - [x] matrix-market
    - [x] binary version of some entries and symmetries
- [x] provide binaries
  - [x] linux / amd64
  - [x] linux / ppc64le
  - [x] macOS / amd64
  - [x] windows / amd64
- [x] download datasets
  - [x] list datasets (`download --list`)
  - [x] filter by regex (`download "graph500*"`)
  - [x] filter by source (`download --provider GraphChallenge`)
  - [x] filter by format (`download --format mtx`)

## In Progress

- [ ] Download of datasets
    - [x] [Twitter](http://an.kaist.ac.kr/traces/WWW2010.html)
    - [x] [Static Graph Challenge](https://graphchallenge.mit.edu/data-sets)
    - [ ] [Sparse Challenge](https://graphchallenge.mit.edu/data-sets)
    - [ ] [Matrix Market](https://math.nist.gov/MatrixMarket/browse.html)
    - [ ] [SuiteSparse](https://sparse.tamu.edu/)

## Not yet started
- [ ] Visualization of datasets
- [ ] Verification of datsets
- [ ] partitioning datasets

## Making a Release

1. Increment the package version in `graph_datasets2.nimble`.
2. Commit that change
3. Create a matching git tag
4. Push that tag
5. Go onto github and make the draft release a real release

*Copyright Carl Pearson 2019*

## Formats

### TSV

### BEL

### Twitter