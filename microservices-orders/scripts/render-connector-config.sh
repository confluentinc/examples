#!/bin/bash

cat <(eval "cat <<EOF
$(<$INPUT_FILE)
EOF
") > $OUTPUT_FILE
