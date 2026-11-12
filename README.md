# deploy-bind

Despliega BIND9 como servidor DNS maestro o esclavo en Debian 13.

## Contenido
- `deploy-bind.sh`: script principal.
- `vars.env`: variables del entorno (dominio, red e IPs de los servidores).
- `templates/`: plantillas de configuración y zonas (usan variables `${...}`).

## Requisitos
Debian 13, usuario root, conexión a Internet para instalar paquetes.

## Uso
1. Edita `vars.env` con tu dominio y tu red.
2. Ejecuta `sudo ./deploy-bind.sh master` en el servidor maestro, o `slave` en el esclavo.

## Qué hace
Instala BIND9, guarda una copia de /etc/bind, genera la configuración desde las
plantillas, valida con named-checkconf/named-checkzone, reinicia y comprueba el SOA.

## Avisos
- En el maestro genera una clave TSIG nueva (/etc/bind/ddns.key) si no existe.
  Su secreto debe copiarse a la configuración de Kea D2 (kea-dhcp-ddns.conf).
- Las zonas existentes no se sobrescriben, para no perder los registros dinámicos.
- Es idempotente: se puede ejecutar varias veces.
