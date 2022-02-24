1. ssh to worker box
1. cd to current
1. rails console
1. set IndexManager last dump completed to bad dump.  Bad dump will be the current dump in progress 
1. set dump in progress to nil
1. set in progress to false
1. save the index manager
1. on index manager call index_remaining!
