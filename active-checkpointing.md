# Active-Checkpointing
COLO solves the memory checkpointing issue by keeping a local copy of the previous checkpoint's memory contents, and reverting locally modified memory pages to the previous checkpoint before applying the delta memory pages from the PVM.

![active-checkpointing](https://github.com/wangchenghku/COLO/blob/master/.resources/active-checkpointing.png)