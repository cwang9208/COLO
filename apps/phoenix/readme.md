## The Phoenix System
- *Phonenix*: a shared-memory implementation of MapReduce
  - Use threads instead of cluster nodes for parallelism
  - Communicates through shared memory instead of network messages
    - Works with CMP and SMP systems
  - Current version works with C/C++ and uses P-threads
    - Easy to port to other languages or thread environments

## Applications
* Word count - determine frequency of words in documents
* Linear regression - find the best fit line for a set of points
* ...

## Phoenix Vs. P-threads
The Phoenix benchmark suite provides two implementations per algorithm, one using regular Pthreads and the other using a map-reduce library atop Pthreads.

For three applications (Kmeans, PCA, and Histogram), P-threads outperforms Phoenix significantly. For these applications, the MapReduce program structure is not an efficient fit.
* Histogram
  * There is no need for keys in original algorithm
* Kmeans
  * Multiple MapReduce invocation with translation step
