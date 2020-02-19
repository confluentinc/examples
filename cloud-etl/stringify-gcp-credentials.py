# python3 stringify-gcp-credentials.py gcp-credentials.json output.txt
#!/usr/bin/python

import os
import sys
import json

script_path = os.path.abspath(__file__) # i.e. /path/to/dir/foobar.py
script_dir = os.path.split(script_path)[0] #i.e. /path/to/dir/
rel_path_input = sys.argv[1]

abs_file_path_input = os.path.join(script_dir, rel_path_input)

with open(abs_file_path_input) as f:
  data = json.load(f)

print(json.dumps(json.dumps(data)))
