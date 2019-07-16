# graph-datasets2

Convert twitter_rv.net from `http://an.kaist.ac.kr/traces/WWW2010.html` to bel format.

## Building

```
nimble build -d:release
./graph_datasets2 convert twitter_rv.net twitter_rv.bel
```

## To Do

- [ ] Download of datasets
- [ ] Verification of datsets
- [ ] listing / filtering datasets
- [ ] statistics of datasets
- [ ] relabeling of vertex IDs
  - [ ] lower triangular
  - [ ] upper triangular
  - [ ] degree-ordered
  - [ ] graph compaction from Bisson & Fatica [Update on Static Graph Challenge on GPUs](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=8547514) (2018)
- [ ] partitioning datasets
