#!/bin/bash
export LD_LIBRARY_PATH=~/:$LD_LIBRARY_PATH
# export LD_PRELOAD=~/libstdc++.so.6 #/lib/libgcc_s.so.1      
#/afs/csail.mit.edu/system/amd64_linux26/matlab/latest/bin/matlab -nosplash ${1}
/afs/csail.mit.edu/system/amd64_linux26/matlab/latest/bin/matlab -nodesktop -nosplash -nodisplay ${1}
