Pasar cuentas inactivas por X cantidad de días a estado "Locked" o "Closed"
Probado en Zimbra FOSS 8.8.15
Si la versión es anterior, verificar la ruta del LDAPSEARCH, porque eso es lo unico que cambia de lugar.

Fuente: https://soporte.itlinux.cl/hc/es/articles/208315233-Bloqueo-de-cuentas-inactivas-LastLogon-

#!/bin/bash

LDAP_SERVER=`/opt/zimbra/bin/zmlocalconfig ldap_host | cut -d '=' -f2`
LDAP_PASS=`/opt/zimbra/bin/zmlocalconfig -s zimbra_ldap_password | cut -d ' ' -f3`
LDAP_USERDN=`/opt/zimbra/bin/zmlocalconfig zimbra_ldap_userdn | awk '{print $3}'`
LDAPSEARCH="/opt/zimbra/common/bin/ldapsearch -x -h $LDAP_SERVER -D $LDAP_USERDN -w$LDAP_PASS -LLL -o ldif-wrap=no "
ZMPROV="/opt/zimbra/bin/zmprov"
filetemp="/tmp/resultado.txt"

valor="zimbraLastLogonTimestamp"
dias="180" # numero de dias de antiguedad


today=`date +%Y%m%d` # obtiene la fecha de hoy YYYYMMDD
epoch_today=`date --date $today +%s`

# Saca el listado de cuentas obtienen el atributo $valor
$LDAPSEARCH "(&(objectClass=zimbraAccount)($valor=*))" $valor | sed 's/ou=people,//g' | sed 's/dn: uid=/:/g' | sed 's/,dc=/@/' | sed 's/,dc=/./g' | sed 's/,dc=/./g' | sed ':a;N;$!ba;s/\n/ /g' | sed "s/$valor: //g" | sed 's/:/\n/g' > $filetemp

echo "Listado de cuentas que no inician sesion hace mas de $dias dias: (Copie y pegue esta salida como usuario zimbra)"
echo

while read line; do
user=`echo $line | awk '{print $1}'`
fecha=`echo $line | awk '{print $2}'`
if [ "$fecha" == "" ]; then
continue
fi
dfecha=`echo $fecha | cut -c1-8` # extrae los 8 primeros caracteres YYYYMMDD
epoch_dfecha=`date --date $dfecha +%s`

resta=`expr $epoch_today - $epoch_dfecha`
days=`expr $resta / 86400`

if [ $days -gt $dias ]; then
echo "zmprov ma $user zimbraAccountStatus locked"
fi
done < $filetemp

rm -f $filetemp

