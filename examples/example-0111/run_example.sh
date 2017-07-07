#!/bin/bash

echo "compiling and running example $(pwd)"

folder=$1

mkdir -p $folder

echo "  compiling $folder"
cd $folder
cmake -DCMAKE_BUILD_TYPE=$folder -DOPENCMISS_BUILD_TYPE=$folder ..
make
cd ..
echo "  running $folder"
#mkdir -p results/current_run && ./$folder/src/example
#mkdir -p results/current_run && ./$folder/src/example 160 120 0 32 24 0 1 0 10000 0.3 0.025
# These are the linear elasticity tests for uniaxial extension (force driven)
# 2D Tests
echo "    2D tests"
mkdir -p results/current_run/l160x120x000_n08x06x00_i1_s0 && ./$folder/src/example 160 120 0 8 6 0 1 0 10000 0.3 20000
mkdir -p results/current_run/l160x120x000_n16x12x00_i1_s0 && ./$folder/src/example 160 120 0 16 12 0 1 0 10000 0.3 20000
mkdir -p results/current_run/l160x120x000_n32x24x00_i1_s0 && ./$folder/src/example 160 120 0 32 24 0 1 0 10000 0.3 20000
# 3D Tests
echo "    3D tests"
mkdir -p results/current_run/l160x120x120_n08x06x06_i1_s0 && ./$folder/src/example 160 120 120 8 6 6 1 0 10000 0.3 0.200000
mkdir -p results/current_run/l160x120x120_n16x12x12_i1_s0 && ./$folder/src/example 160 120 120 16 12 12 1 0 10000 0.3 0.200000
mkdir -p results/current_run/l160x120x120_n32x24x24_i1_s0 && ./$folder/src/example 160 120 120 32 24 24 1 0 10000 0.3 0.200000
#
# Write out x-displacements into a Text-File (-> Gives a list as ASCII-File [1,last_node])
#
cp results/get_displacement.pl results/current_run/l160x120x000_n08x06x00_i1_s0/ && cd results/current_run/l160x120x000_n08x06x00_i1_s0/ && ./get_displacement.pl && cd ../../../
cp results/get_displacement.pl results/current_run/l160x120x000_n16x12x00_i1_s0/ && cd results/current_run/l160x120x000_n16x12x00_i1_s0/ && ./get_displacement.pl && cd ../../../
cp results/get_displacement.pl results/current_run/l160x120x000_n32x24x00_i1_s0/ && cd results/current_run/l160x120x000_n32x24x00_i1_s0/ && ./get_displacement.pl && cd ../../../
cp results/get_displacement.pl results/current_run/l160x120x120_n08x06x06_i1_s0/ && cd results/current_run/l160x120x120_n08x06x06_i1_s0/ && ./get_displacement.pl && cd ../../../
cp results/get_displacement.pl results/current_run/l160x120x120_n16x12x12_i1_s0/ && cd results/current_run/l160x120x120_n16x12x12_i1_s0/ && ./get_displacement.pl && cd ../../../
cp results/get_displacement.pl results/current_run/l160x120x120_n32x24x24_i1_s0/ && cd results/current_run/l160x120x120_n32x24x24_i1_s0/ && ./get_displacement.pl && cd ../../../
