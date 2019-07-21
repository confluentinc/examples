#!/usr/bin/env python

# Dynamically create the login.properties file used by the Hash Login service
# Creates a file in /tmp/login.properties

import os;

configfile = "../config/local-demo.env"
fileHandler = open (configfile, "r")

login_properties = "/tmp/login.properties"
if os.path.exists (login_properties):
  os.remove(login_properties)
loginfile = open (login_properties, "w")
 
# Get list of all lines in file
listOfLines = fileHandler.readlines()
 
# Close file 
fileHandler.close()

for line in listOfLines:
    if line.startswith("USER_"):
      line = line[5:]
      line = line.rstrip()
      user,username = line.split("=", 1)
      loginfile.write(username + ":" + username + "1\n")

loginfile.close()
