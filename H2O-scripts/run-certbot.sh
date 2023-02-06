# need to login to aws console route53 and create a TXT record manually
# when certbot command is run, it prints the DNS name and Text to put into route53
# output is in the certbot/conf/live/apps.lagshared.sschmidt.ch directory
# or certbot/conf/archive/apps.lagshared.sschmidt.ch directory

# NOTE: can specify multiple domains with multiple --domain "bla.bla.bla" arguments
certbot certonly --dry-run --manual -m schmidtst@vmware.com --preferred-challenges dns-01 --domain "*.apps.lagshared.sschmidt.ch" --logs-dir ./certbot/logs --work-dir ./certbot/work --config-dir ./certbot/conf

#    total 8
#    -rw-r--r--  1 schmidtst  staff  692 Nov 23 15:53 README
#    lrwxr-xr-x  1 schmidtst  staff   50 Nov 23 15:53 cert.pem -> ../../archive/apps.lagshared.sschmidt.ch/cert1.pem
#    lrwxr-xr-x  1 schmidtst  staff   51 Nov 23 15:53 chain.pem -> ../../archive/apps.lagshared.sschmidt.ch/chain1.pem
#    lrwxr-xr-x  1 schmidtst  staff   55 Nov 23 15:53 fullchain.pem -> ../../archive/apps.lagshared.sschmidt.ch/fullchain1.pem
#    lrwxr-xr-x  1 schmidtst  staff   53 Nov 23 15:53 privkey.pem -> ../../archive/apps.lagshared.sschmidt.ch/privkey1.pem
#    
#    total 40
#    -rw-r--r--  1 schmidtst  staff  1606 Nov 23 15:53 cert1.pem
#    -rw-r--r--  1 schmidtst  staff  3749 Nov 23 15:53 chain1.pem
#    -rw-r--r--  1 schmidtst  staff  5355 Nov 23 15:53 fullchain1.pem
#    -rw-------  1 schmidtst  staff   241 Nov 23 15:53 privkey1.pem
#    
#     # 1119  certbot certonly --dry-run --manual --preferred-challenges dns-01 --domain "*.apps.lagshared.sschmidt.ch" --logs-dir ./certbot/logs --work-dir ./certbot/work --config-dir ./certbot/conf
#     # 1129  certbot certonly --manual --preferred-challenges dns-01 --domain "*.apps.lagshared.sschmidt.ch" --logs-dir ./certbot/logs --work-dir ./certbot/work --config-dir ./certbot/conf

# NOTE: the secret name "dashboard-selfsigned-cert-tls" is a misnomer, just choosen because the install-dashboard.sh script creates it

kubectl create secret tls dashboard-selfsigned-cert-tls -n kubernetes-dashboard --cert fullchain1.pem --key privkey1.pem
