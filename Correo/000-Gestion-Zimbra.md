Listar Cuentas que tienen reenvios (fordward) a cuentas externas

for account in `zmprov -l gaa`; do zmprov ga $account zimbraPrefMailForwardingAddress; done