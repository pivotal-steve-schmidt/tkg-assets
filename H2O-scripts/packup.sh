#!/bin/bash

# backup files to preserve changes

DIR="/tmp"
FILE="scripts"
LIST="./.secrets ./scripts"

out="${DIR}/$(date +'%Y%m%d_%H%M_')${FILE}.tar"

tar cvf ${out} ${LIST}

echo "Ready to copy from ${DIR}:"
echo "  cp $DIR/$out ."
