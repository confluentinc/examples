export JAVA_HOME=/opt/oracle/product/12.2.0.1/dbhome_1/jdk/jre/ 
export PATH=$PATH:$JAVA_HOME/bin:/home/oracle/swingbench/bin 
oewizard -cs localhost:1521/ORCLPDB1 -cl -dbap Password01 -drop -u soe -v 
oewizard -cs localhost:1521/ORCLPDB1 -df /opt/oracle/oradata/ORCLCDB/ORCLPDB1/soe.dbf -cl -scale 0.01 -dbap Password01 -create -u soe -p soe -ts soe -v
