yum -y install https://grafanarel.s3.amazonaws.com/builds/grafana-2.6.0-1.x86_64.rpm
yum -y install grafana-opennms-plugin

systemctl enable grafana-server
systemctl start grafana-server

firewall-cmd --zone=public --permanent --add-port=3000/tcp
sleep 10
curl 'http://admin:admin@localhost:3000/api/datasources' -X POST -H 'Content-Type:application/json;charset=UTF-8' --data-binary '{"name":"OpenNMS","type":"opennms","access":"proxy","url":"http://localhost:8980/opennms","isDefault":true,"basicAuth":true,"basicAuthUser":"admin","basicAuthPassword":"admin"}'
