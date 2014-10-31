#!/bin/bash

for node in `cat nodes`; do
docker stop $node &&
docker rm $node ;
done
