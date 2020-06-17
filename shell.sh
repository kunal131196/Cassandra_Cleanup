#!/bin/bash

if [ -f etl_tool-assembly-0.9.42.jar ] ;then
	echo "jar already present"
else
	wget http://apk-repo.yagnaiq.com/etl/etl_tool-assembly-0.9.42.jar
fi
#############################################################################################################################################
if [ -f etl_tool-assembly-0.9.42.jar ] ;then

touch time_complete.txt

echo $(date +%Y-%m-%d-%H-%M) > time_complete.txt
. ./project.properties

if [ -f project.properties ]; then

###############################################################################################################################################
################################### Altering gc values of tables #############################################################################
#############################################################################################################################################
if [ -f GracePeriodChanges ]; then

cat GracePeriodChanges

script -c "cqlsh --request-timeout=360000 $CASSANDRAIP -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"use $CASSANDRA_KEYSPACE;SOURCE 'GracePeriodChanges'\"" GracePeriodChanges.txt

if [ $? -eq 0 ]; then
	echo "Done Successfully"
else
	echo "Failure"
	exit 1
fi
else
	echo "Please check GracePeriodChanges cql queries not present"
fi
echo "Please check grce period of keyspace below"
script -c "cqlsh --request-timeout=360000 $CASSANDRA_IP -u $CASSANDRA_USER -p $CASSANDRA_PASS -e 'desc keyspace $CASSANDRA_KEYSPACE'"
rm -rf typescript
#################################################################################################################################################
################## Running Deletion ETL jobs ###################################################################################################
###############################################################################################################################################

for folder in `ls -d1 */|tr -d "/"|sort -n`
do
	if [ -f $folder/job.yml ]; then
		cp $folder/job.yml .
		sed -i "s/ETL_TIMESTAMP1/$ETL_TIMESTAMP1/g" job.yml
		sed -i "s/CASSANDRAIP/$CASSANDRAIP/g" job.yml
		sed -i "s/CASSANDRA_KEYSPACE/$CASSANDRA_KEYSPACE/g" job.yml
		sed -i "s/CASSANDRA_USER/$CASSANDRA_USER/g" job.yml
		sed -i "s/CASSANDRA_PASS/$CASSANDRA_PASS/g" job.yml
                sed -i "s/ETL_TIMESTAMP2/$ETL_TIMESTAMP2/g" job.yml
		echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		cat job.yml
                echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
		script -c "java -jar etl_tool-assembly-0.9.42.jar " $folder.txt
		if [ $? -eq 0 ]; then
	        	echo "Done Successfully"
		else
	        	echo "Failure"
	        	exit 1
		fi
		checkerror=`cat $folder.txt|grep ERROR|wc -l`
	        if [ $checkerror != "0" ]; then
        	        echo "Getting some error while running $folder"
	                exit 1
        	fi

	else
		echo "Please check job yml not present for $folder"
	fi
done
#######################################################################################################################
############# Compaction task #########################################################################################
######################################################################################################################
if [ -f table ]; then
for table in `cat table`
do
nodetool compact $CASSANDRA_KEYSPACE $table
sleep 15
done
else 
    " File table is not present"
fi
#######################################################################################################################
##### Altering grace period for all the tables #######################################################################
######################################################################################################################

if [ -f PostgraceChanges ]; then

cat PostgraceChanges

script -c "cqlsh --request-timeout=360000 $CASSANDRAIP -u $CASSANDRA_USER -p $CASSANDRA_PASS -e \"use $CASSANDRA_KEYSPACE;SOURCE 'PostgraceChanges'\"" GracePeriodChanges.txt

if [ $? -eq 0 ]; then
        echo "Done Successfully"
else
        echo "Failure"
        exit 1
fi

else
        echo "Please check GracePeriodChanges cql queries not present"
        exit 1
fi
###############################################################################################################################
##########Function for clearing snapshots created post truncate operation #####################################################
###############################################################################################################################

clearsnap() {
local ks=$1
nodetool clearsnapshot -- $ks
sleep 20
}

###################################################################################################################################
################################################## Calling snapshot clear ########################################################
##################################################################################################################################
clearsnap "$CASSANDRA_KEYSPACE"
##################################################################################################################################
else
        echo "project properties file is not present"
	exit 1

fi
else
        echo " Please check jar is not downloaded properly" 
        exit 1
fi
