#!/bin/bash

for name in world_{10,50,110}m; do
    echo generating ${name}.m
    bzip2 -dc ${name}.txt.bz2 | awk -v name=$name -f coastline2octave.awk > ${name}.m
done

cat <<EOF | octave
printf('generating world_10m.mat\n');
tic;
c=world_10m;
save -mat world_10m.mat c
toc

printf('generating world_50m.mat\n');
tic;
c=world_50m;
save -mat world_50m.mat c
toc

printf('generating world_110m.mat\n');
tic;
c=world_110m;
save -mat world_110m.mat c
toc
EOF
