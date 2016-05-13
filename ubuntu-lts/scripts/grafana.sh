printf 'deb https://packagecloud.io/grafana/%s/debian/ wheezy main' "stable"> /etc/apt/sources.list.d/grafana.list
wget -q -O - https://packagecloud.io/gpg.key | sudo apt-key add -
apt-get update
apt-get install -y grafana
systemctl enable grafana-server
systemctl start  grafana-server
sleep 5
grafana-cli plugins install opennms-datasource
curl 'http://admin:admin@localhost:3000/api/datasources' -X POST -H 'Content-Type:application/json;charset=UTF-8' --data-binary '{"name":"OpenNMS","type":"OpenNMS","access":"proxy","url":"http://localhost:8980/opennms","isDefault":true,"basicAuth":true,"basicAuthUser":"admin","basicAuthPassword":"admin"}'
