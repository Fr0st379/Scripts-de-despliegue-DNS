#!/bin/bash
#Despliegue de BIND9 (maestro o esclavo) a partir de plantillas
#USO	sudo ./deploy-bind.sh master|slave
#Requisitos debian 13, ejecutar como root y los archivos de plantillas y variables
#Acciones que realiza:
#			1) Instala Bind9
#			2) Copia de seguridad de /etc/bind
#			3) genera la configuración desde las plantillas
#			4) (maestro) Crea la clave TSIG y las zonas si no existen
#			5) valida, reinicia y verifica
set -euo pipefail

ROLE="${1:-}"
[[ "$ROLE" == "master" || "$ROLE" == "slave" ]] || { echo "Uso: $0 master|slave" >&2; exit 1; }
[[ $EUID -eq 0 ]] || { echo "Ejecuta como root" >&2; exit 1; }

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/vars.env"
export DOMAIN NET NS1_IP NS2_IP HOLE_IP
export NS1_HOST="${NS1_IP##*.}" NS2_HOST="${NS2_IP##*.}" HOLE_HOST="${HOLE_IP##*.}"
VARS='${DOMAIN} ${NET} ${NS1_IP} ${NS2_IP} ${HOLE_IP} ${NS1_HOST} ${NS2_HOST} ${HOLE_HOST}'
vars='${DOMAIN} ${NET} ${NS1_IP} ${NS2_IP} ${HOLE_IP} ${NS1_HOST} ${NS2_HOST} ${HOLE_HOST}'

echo "[1/5] Instalando Paquetes requeridos"
apt-get update -qq || echo " aviso: No se pudo actualizar el índice de paquetes, (¿error de configuración de red?)"
apt-get install -y -qq bind9 bind9-utils bind9-dnsutils gettext-base

echo "[2/5] Copia de seguridad de /etc/bind"
cp -a /etc/bind "/etc/bind.back.$(date +%Y%m%d-%H%M%S)"

echo "[3/5] Generación de configuración desde las plantillas ($ROLE)"
install -d -o bind -g bind /var/lib/bind /var/log/named
envsubst "$VARS" < "$DIR/templates/named.conf.options.tpl"	> /etc/bind/named.conf.options
envsubst "$VARS" < "$DIR/templates/named.conf.local.$ROLE.tpl"	> /etc/bind/named.conf.local
if [[ "$ROLE" == "master" ]]; then
  echo "[4/5] Clave TSIG y zonas (solo si no existen)"
  # La clave no va en las plantillas: se genera aquí y su secreto se copia luego a Kea D2
  [[ -f /etc/bind/ddns.key ]] || tsig-keygen -a hmac-sha256 ddns-key > /etc/bind/ddns.key
  chown root:bind /etc/bind/ddns.key && chmod 640 /etc/bind/ddns.key
  # Las zonas no se sobrescriben si ya existen, para no perder los registros dinámicos (DDNS)
  [[ -f "/var/lib/bind/db.$DOMAIN" ]]      || envsubst "$VARS" < "$DIR/templates/db.fwd.tpl" > "/var/lib/bind/db.$DOMAIN"
  [[ -f "/var/lib/bind/db.192.168.$NET" ]] || envsubst "$VARS" < "$DIR/templates/db.rev.tpl" > "/var/lib/bind/db.192.168.$NET"
  chown bind:bind /var/lib/bind/db.*
else
  echo "[4/5] Esclavo: las zonas llegan de por transferencia desde $NS1_IP"
fi

echo "[5/5] Validando, reiniciando y verificando"
named-checkconf
if [[ "$ROLE" == "master" ]]; then
  named-checkzone "$DOMAIN" "/var/lib/bind/db.$DOMAIN"
  named-checkzone "$NET.168.192.in-addr.arpa" "/var/lib/bind/db.192.168.$NET"
fi
systemctl enable named
systemctl restart named
if ! systemctl is-active --quiet named; then echo "ERROR: named no arrancó" >&2; exit 1; fi
sleep 3   # margen para que el esclavo reciba la zona
echo "SOA de $DOMAIN:"; dig @127.0.0.1 "$DOMAIN" SOA +short
