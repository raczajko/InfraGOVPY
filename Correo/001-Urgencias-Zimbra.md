En caso de contar con Proxmox Mail Gateway (PMG), se puede borrar correos en cola (cuenta SPAM):

find /var/spool/postfix -type f | xargs -n 1000 grep -l  XXXX@YYYY.gov.py | sed 's/.*\///g' | postsuper -d -


*Zimbra*:

1 - Borrar correos de un usuario SPAM, en la cola "activa"
/opt/zimbra/common/sbin/postqueue -p | egrep -v '^ *\(|-Queue ID-' | awk 'BEGIN { RS = "" } { if ($7 == "XXX@YYY.gov.py") print $1} ' | tr -d '*!' | /opt/zimbra/common/sbin/postsuper -d -


2 - Mandar todos los correos a "Hold" y ganar tiempo para no seguir emitiendo SPAM
/opt/zimbra/common/sbin/postsuper -h ALL