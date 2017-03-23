#!/bin/bash

docker run -v $(pwd):/tmp/builds/ -it go-compiler /builds/k2http.sh
