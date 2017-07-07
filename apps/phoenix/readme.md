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
