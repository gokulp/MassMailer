f1 ()
{
	echo $1
}

f1 inner_arg
A="MYRUN_0001"

echo $A | awk -F"RUN_" '{print $2}'
