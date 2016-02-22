# Install patch
yum -y install patch

cd /opt/opennms/jetty-webapps/opennms/admin/ng-requisitions/app/scripts/directives
curl https://gist.githubusercontent.com/indigo423/bb7fe3fcfa912ad91623/raw/88f5ffb1f775259b2fe4455e1a8d5f5244f825ee/NMS-8153.patch -o NMS-8153.patch
patch -p0 < NMS-8153.patch

