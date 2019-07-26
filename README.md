# graph-datasets2

master: [![Build Status](https://travis-ci.org/cwpearson/graph-datasets2.svg?branch=master)](https://travis-ci.org/cwpearson/graph-datasets2)

develop: [![Build Status](https://travis-ci.org/cwpearson/graph-datasets2.svg?branch=develop)](https://travis-ci.org/cwpearson/graph-datasets2)

Manage a variety of graph datasets

Download [the latest release](https://github.com/cwpearson/graph-datasets2/releases/latest) for your platform.

## Features

* Conversion between multiple formats
* Resumable downloads (for large datasets)
* Some statistics on a variety of datasets

## Building

Install the latest stable version of nim, then

```
nimble build -d:release
./graph_datasets --help
./tc --help
```

## Complete

- [x] statistics of datasets
- [x] orient graphs
  - [x] lower triangular
  - [x] upper triangular
  - [x] degree-ordered
- [x] relabeling of vertex IDs
  - [x] graph compaction from Bisson & Fatica [Update on Static Graph Challenge on GPUs](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=8547514) (2018)
- [x] File formats
  - [x] graph challenge tab-separated values
    - [x] direct version
  - [x] matrix-market coordinate real
    - [x] binary version
- [x] provide binaries
  - [x] linux / amd64
  - [x] linux / ppc64le
  - [x] macOS / amd64
  - [x] windows / amd64

## In Progress

- [ ] Download of datasets
    - [x] [Twitter](http://an.kaist.ac.kr/traces/WWW2010.html)
    - [x] a few graph challenge datasets 
    - [ ] [Matrix Market](https://math.nist.gov/MatrixMarket/browse.html)
    - [ ] [SuiteSparse](https://sparse.tamu.edu/)
    - [ ] listing / filtering datasets
      - [x] preliminary filtering by name
      - [ ] filter by source (`--source graphchallenge`)
      - [ ] filter by name (`--name "graph500*"`)
      - [ ] filter by format (`--format mtx`)
    - [ ] `--continue` flag to resume a download

## Not yet started
- [ ] Visualization of datasets
- [ ] Verification of datsets
- [ ] partitioning datasets
- [ ] file support: matrix-market coordinate data types and symmetries (required for Matrix Market and SuiteSparse)

## Making a Release

1. Increment the package version in `graph_datasets2.nimble`.
2. Commit that change
3. Create a matching git tag
4. Push that tag
5. Go onto github and make the draft release a real release

*Copyright Carl Pearson 2019*