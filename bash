#!/bin/sh
exec docker run -v `pwd`:/home/runner/src --rm -it graphableos-crosscompiler bash $@
