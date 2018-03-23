#!/bin/bash
 
# call mysql client from shell script without 
# passing credentials on command line
 
# This demonstrates small single queries using
# the -e parameter.   Credentials and connection
# info are sent through standard input.
 
# david . bennett @ percona . com - 12/27/2016

#save these variable into postfix-postogin.conf file 
#mysql_user=root
#mysql_password=password
#mysql_host=127.0.0.1
#mysql_port=3306
#mysql_database=test

source postfix-postlogin.conf
 
mysql_exec() {
  local query="$1"
  local opts="$2"
  mysql_exec_result=$(
    printf "%s\n" \
      "[client]" \
      "user=${mysql_user}" \
      "password=${mysql_password}" \
      "host=${mysql_host}" \
      "port=${mysql_port}" \
      "database=${mysql_database}" \
      | mysql --defaults-file=/dev/stdin "${opts}" -e "${query}"
  )
}
 
#sasl_username
declare -A data_in
while IFS='$\n' read -r line; do
    # do whatever with line
    if [ ! -z $line ];then
        var=${line%=*}
        val=${line#*=}    
        data_in[${var}]="${val}"
    fi
done



if [ ${data[request]}=="smtpd_access_policy" -a \( ! -z ${data_in[client_address]} \) -a \( ! -z ${data_in[sasl_username]} \) ];then

   # echo "UPDATE mail_users A INNER JOIN domain B ON A.domain_id=B.domain_id SET last_login_date=NOW(),last_login_proto='SMTP',last_login_ip='"${data_in[client_address]}"' WHERE CONCAT(A.mail_acc, '@', B.domain_name)='"${data_in[sasl_username]}"' LIMIT1"
   mysql_exec "UPDATE mail_users A INNER JOIN domain B ON A.domain_id=B.domain_id SET last_login_date=NOW(),last_login_proto='SMTP',last_login_ip='"${data_in[client_address]}"' WHERE CONCAT(A.mail_acc, '@', B.domain_name)='"${data_in[sasl_username]}"' LIMIT1"

fi

echo "action=dunno

"

exit 0