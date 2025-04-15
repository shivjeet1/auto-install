#!/bin/bash

set -e 

# Dirs
work_dir=/tmp/auto-ins
profile=$work_dir/
iso_out=/tmp/auto-ins/out

mkdir -p $iso_out

# Setup
pacman --noconfirm -S archiso

cp -r /usr/share/archiso/configs/releng/* $work_dir/.

cp -r arch.sh config.json $work_dir/airootfs/root/.

cat >> $work_dir/root/.zprofile << EOF
  # unattended installation begins
  bash arch.sh
EOF

# ISO build
mkarchiso -v -w $work_dir -o $iso_out $profile 
