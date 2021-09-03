Listar Cuentas que tienen reenvios (fordward) a cuentas externas

for account in `zmprov -l gaa`; do zmprov ga $account zimbraPrefMailForwardingAddress; done


Verificar permisos sobre lista cuando no aplica sobre la interfaz Administrativa Web:
zmprov ckr dl lista@entidad.gov.py correo_persona@entidad.gov.py sendToDistList

Dar permisos sobre la lista: (a veces sobre la interfaz web incluso falla)
zmprov ckr dl lista@entidad.gov.py correo_persona@entidad.gov.py sendToDistList
