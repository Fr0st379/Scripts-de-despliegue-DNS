include "/etc/bind/ddns.key";   // la genera el script; no se guarda en la plantilla

zone "${DOMAIN}" {
        type primary;
        file "/var/lib/bind/db.${DOMAIN}";
        allow-transfer { esclavos; };
        allow-update { key "ddns-key"; };
};
zone "${NET}.168.192.in-addr.arpa" {
        type primary;
        file "/var/lib/bind/db.192.168.${NET}";
        allow-transfer { esclavos; };
        allow-update { key "ddns-key"; };
};
