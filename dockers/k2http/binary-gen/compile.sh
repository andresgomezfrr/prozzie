#!/bin/bash

docker run -v $(pwd):/tmp/builds/ -it gcr.io/wizzie-registry/go-compiler:latest /builds/k2http.sh
