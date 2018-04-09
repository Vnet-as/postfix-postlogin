#!/bin/bash
 
# call mysql client from shell script without 
# passing credentials on command line
# Peter Vilhan
#

#save these variables into postfix-postogin.conf file 
#user=xyz
#password=strong_paass121
#host=10.0.0.1 
#port=3306
#database=db_name
#logfile=/path/to/logfile
#debug=0

SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`
source $SCRIPTPATH/postfix-postlogin.conf
 
mysql_exec() {
  local query="$1"  
  mysql_exec_result=$(
    printf "%s\n" \
      "[client]" \
      "user=${mysql_user}" \
      "password=${mysql_password}" \
      "host=${mysql_host}" \
      "port=${mysql_port}" \
      | /usr/bin/mysql --defaults-file=/dev/stdin -D "${mysql_database}" -e "${query}" 
  )
  if [ ! -z $mysql_exec_result];then 
        echo `date` ": $mysql_exec_result
" >> ${logfile}
  fi
}

if [ $debug -eq 1 ];then
    echo "Data in:\n" >> ${logfile} 
fi

#parse postfix attributes 
declare -A data_in
while IFS='$\n' read -r line; do
    # do whatever with line
    if [ ! -z $line ];then
        var=${line%=*}
        val=${line#*=}    
        data_in[${var}]="${val}"
    else
        if [ $debug -eq 1 ];then
                echo "Zaznamenane: ${data_in[@]}\n" >> ${logfile} 
        fi
        break
    fi

    if [ $debug -eq 1 ];then
        echo "Parsed: $var=$val" >> ${logfile}
    fi
done


if [ $debug -eq 1 ];then
    echo "Decision: req: ${data_in[request]} ip: ${data_in[client_address]} login: ${data_in[sasl_username]}\n" >> ${logfile} 
fi

if [ ${data_in[request]}=="smtpd_access_policy" -a \( ! -z ${data_in[client_address]} \) -a \( ! -z ${data_in[sasl_username]} \) ];then
   #treba prerobit update WHERE A.mail_acc='peter.vilhan' AND B.domain_name='vnet.eu'

   login=`echo ${data_in[sasl_username]} | cut -d'@' -f1`
   domain=`echo ${data_in[sasl_username]} | cut -d'@' -f2`

   mysql_exec "UPDATE mail_users A INNER JOIN domain B ON A.domain_id=B.domain_id SET last_login_date=NOW(),last_login_proto='SMTP',last_login_ip='"${data_in[client_address]}"' WHERE A.mail_acc='"$login"' AND B.domain_name='"$domain"'"

   if [ $debug -eq 1 ];then
       echo "Runnning:  mysql_exec "UPDATE mail_users A INNER JOIN domain B ON A.domain_id=B.domain_id SET last_login_date=NOW(),last_login_proto='SMTP',last_login_ip='"${data_in[client_address]}"' WHERE A.mail_acc='"$login"' AND B.domain_name)='"$domain"'" > ${logfile}
   fi

fi

printf "%s\n\n\n" "action=DUNNO"


exit 0
