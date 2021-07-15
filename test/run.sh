#!/bin/bash

PROJ=$(cd $(dirname $0)/..; pwd)
ARKAM=$PROJ/bin/arkam
FORTH_IMG=$1

if [ -z $FORTH_IMG ]; then
    echo "Usage: run.sh FORTH_IMG.ark"
    exit 1
fi


cd $PROJ


echo "# ===== test_arkam ====="

./bin/test_arkam || exit 1


echo "===== Forth ($FORTH_IMG) ====="

for src in test/forth/*.f
do
    echo -n "$src .."
    ./bin/arkam $FORTH_IMG $src || exit 1
    echo "ok"
done
