printf 'deb https://packagecloud.io/grafana/%s/debian/ wheezy main' "stable"> /etc/apt/sources.list.d/grafana-stable.list
wget -q -O - https://packagecloud.io/gpg.key | sudo apt-key add -
apt-get update
apt-get install -y grafana
update-rc.d grafana-server defaults 95 10
service grafana-server start
apt-get install -y grafana
update-rc.d grafana-server defaults 95 10
apt-get install -y grafana-opennms-plugin
service grafana-server start
curl 'http://admin:admin@localhost:3000/api/datasources' -X POST -H 'Content-Type:application/json;charset=UTF-8' --data-binary '{"name":"OpenNMS","type":"opennms","access":"proxy","url":"http://localhost:8980/opennms","isDefault":true,"basicAuth":true,"basicAuthUser":"admin","basicAuthPassword":"admin"}'
