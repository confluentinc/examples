#!/bin/bash

# This file is deprecated in favor of the function in ../utils/ccloud_library.sh

# Source library
DIR_THIS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR_THIS}/../utils/ccloud_library.sh

ccloud::generate_configs "$1"
