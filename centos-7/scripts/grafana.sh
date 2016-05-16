sudo yum install https://grafanarel.s3.amazonaws.com/builds/grafana-3.0.2-1463383025.x86_64.rpm
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server
firewall-cmd --zone=public --permanent --add-port=3000/tcp
sleep 5
grafana-cli plugins install opennms-datasource
curl 'http://admin:admin@localhost:3000/api/datasources' -X POST -H 'Content-Type:application/json;charset=UTF-8' --data-binary '{"name":"OpenNMS","type":"OpenNMS","access":"proxy","url":"http://localhost:8980/opennms","isDefault":true,"basicAuth":true,"basicAuthUser":"admin","basicAuthPassword":"admin"}'
