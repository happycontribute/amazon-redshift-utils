#!/bin/bash
#
# This script execute sample evaluation queries against amazon sentiments data
#  with   AQUA turned On and Off
# Arguments are: 
#           -h PGHOST
#           -p PGPORT
#           -U PGUSR
#           -d PGDATABASE
#           -t PGCONNECT_TIMEOUT
# sample run with parameters below :
#./execute_test_queries.sh -h 1.11.11.111 -p 5439 -d dev -U test_user 
#######################################################################################################################

while getopts h:p:U:d:s:e:t:  option; do
      case "${option}" in
          h)
            export PGHOST=${OPTARG}
            ;;
          p)
            export PGPORT=${OPTARG}
            ;;
          d)
            export PGDATABASE=${OPTARG}
            ;;
          U)
            export PGUSER=${OPTARG}
            ;;
          t)
            export PGCONNECT_TIMEOUT=${OPTARG}
            ;;
      esac

done

read -s -p "password to connect to Redshift cluster: " PGPASSWORD
export  PGPASSWORD=$PGPASSWORD
if [[ -z $PGCONNECT_TIMEOUT ]]; then
     export PGCONNECT_TIMEOUT=10
fi

if [[ -z $PGHOST ]] || [[ -z $PGPORT ]] || [[ -z $PGDATABASE ]] || [[ -z $PGUSER ]] ; then
     echo "connection parameters required and cannot be empty, please enter correct  hostname, dbname, port-number, username to connect"
     exit -1
fi
 
AQUAQUERY=$(cat <<QUERYMARKER 

QUERYMARKER
)

RSQUERY=$(cat <<TESTQ

date +"%Y-%m-%d %T" > workload_datetime.txt
     #execute in redhshift three times    
for iter in {1..3}
  do

     psql -c "$AQUAQUERY" -o cap.out > sql_error.log  2>&1 
     CONN_STATUS=$?
     if  [ $CONN_STATUS -eq 2 ]; then
            echo "Connection failed. Please try again with correct connection parameters"
            exit $CONN_STATUS
     fi
     SQL_ERROR=$(cat sql_error.log |  grep -i "error\|failed\|timeout" | wc -l )

            echo "Please check the sql_error.log for erros, once SQL error's fixed and then re-run aqua_execute_query.sh"
            rm -f sql_error.log
            exit $SQL_ERROR
     fi
done
sleep 30
#execute with AQUA on three times
for iter in {1..3}
  do

     psql -c "$RSQUERY" -o capa.out > sql_error.log  2>&1
     CONN_STATUS=$?
     if [ $CONN_STATUS -eq 2 ]; then
           echo "Connection failed. Please try again with correct connection parameters"
           exit $CONN_STATUS
      fi
      SQL_ERROR=$(cat sql_error.log |  grep -i -q "error\|failed\|timeout" | wc -l )

           echo "Please check the sql_error.log for erros, once SQL error's fixed and then  re-run aqua_execute_query.sh"
           rm -f sql_error.log
           exit $SQL_ERROR
      fi
 done
 rm -f  capture_tmp.sql
 rm -f cap.out
 rm -f tmp_capture.sql   
 echo "All queries executed successfully with AQUA and without AQUA, please go ahead and run comparision scripts"
 date +"%Y-%m-%d %T" >> workload_datetime.txt
