$TTL 604800
@     IN SOA srv1.${DOMAIN}. root.${DOMAIN}. (
            2026111201 ; serial
            604800     ; refresh
            86400      ; retry
            2419200    ; expire
            604800 )   ; minimum
      IN NS  srv1.${DOMAIN}.
      IN NS  srv2.${DOMAIN}.
      IN MX  10 mail.${DOMAIN}.
srv1  IN A     ${NS1_IP}
srv2  IN A     ${NS2_IP}
srv3  IN A     ${HOLE_IP}
mail  IN A     ${NS1_IP}
hole  IN CNAME srv3
www   IN CNAME srv1
