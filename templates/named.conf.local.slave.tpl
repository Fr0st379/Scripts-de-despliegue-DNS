zone "${DOMAIN}" {
        type secondary;
        file "/var/cache/bind/db.${DOMAIN}";
        primaries { ${NS1_IP}; };
        allow-notify { ${NS1_IP}; };
        allow-transfer { none; };
};
zone "${NET}.168.192.in-addr.arpa" {
        type secondary;
        file "/var/cache/bind/db.192.168.${NET}";
        primaries { ${NS1_IP}; };
        allow-notify { ${NS1_IP}; };
        allow-transfer { none; };
};
