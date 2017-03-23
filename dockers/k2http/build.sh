#!/bin/bash

echo "1.  Starting k2http compilation..."
cd binary-gen && ./compile.sh
echo "2.  k2http compiled"
cd ../
echo "3.  Starting building k2http Docker image"
docker build -t prozzie-k2http . 
#rm -rf binary-gen/k2http
echo "4.  k2http Docker image created"

