ks=apac_24052020_test
ksa=${ks%%_*}
echo $ksa
n=`nodetool listsnapshots | awk '{print $1}' | grep -F $ks`
echo $n
snapid=${n%%$ksa*}
echo $snapid > snaps.txt
echo  " nodetool clearsnapshot -t $snapid "
