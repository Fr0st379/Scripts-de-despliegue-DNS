acl "red-interna" { 192.168.${NET}.0/24; localhost; };
acl "esclavos"    { ${NS2_IP}; };

options {
        directory "/var/cache/bind";

        // Todo lo que no sea de nuestras zonas se reenvía al sinkhole (Servidor 3)
        forwarders { ${HOLE_IP}; };
        forward only;                    // nunca resolver por su cuenta: obliga a pasar por el filtro

        recursion yes;
        allow-query     { red-interna; };   // quién puede consultar
        allow-recursion { red-interna; };   // quién puede usar la recursión
        allow-transfer  { none; };          // por defecto nadie; cada zona abre lo que necesite

        dnssec-validation auto;
        listen-on-v6 { any; };

        version "none";                  // no revela la versión de BIND
        querylog yes;                    // registra consultas (ampliación de logs)
};

statistics-channels { inet 127.0.0.1 port 8053 allow { 127.0.0.1; }; };

logging {
    channel query_log    { file "/var/log/named/query.log"    versions 5 size 10m; severity info;    print-time yes; print-category yes; };
    channel xfer_log     { file "/var/log/named/xfer.log"     versions 5 size 10m; severity info;    print-time yes; print-category yes; };
    channel update_log   { file "/var/log/named/update.log"   versions 5 size 10m; severity info;    print-time yes; print-category yes; };
    channel security_log { file "/var/log/named/security.log" versions 5 size 10m; severity info;    print-time yes; print-category yes; };
    channel default_log  { file "/var/log/named/named.log"    versions 5 size 10m; severity warning; print-time yes; print-severity yes; };

    category queries  { query_log; };
    category xfer-in  { xfer_log; };
    category xfer-out { xfer_log; };
    category notify   { xfer_log; };
    category update   { update_log; };
    category security { security_log; };
    category default  { default_log; };
};
