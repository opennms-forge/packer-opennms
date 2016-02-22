# Install some tools
yum -y install net-tools wget htop iftop sysstat tcpdump vim git tar unzip psmisc

# Additional packages
yum -y install net-snmp-utils net-snmp
yum -y install bind-utils mailx

# Install OpenNMS repository
rpm -Uvh http://yum.opennms.org/repofiles/opennms-repo-stable-rhel7.noarch.rpm
rpm --import http://yum.opennms.org/OPENNMS-GPG-KEY

# Install OpenNMS without any setup
yum -y install rrdtool
yum -y install opennms
yum -y install jrrd2
yum clean all

# Set Java
/opt/opennms/bin/runjava -s

# Initialize PostgreSQL database
postgresql-setup initdb

# Set authentication from ident to md5
sed -i 's/all             127\.0\.0\.1\/32            ident/all             127.0.0.1\/32            md5/g' /var/lib/pgsql/data/pg_hba.conf
sed -i 's/all             ::1\/128                 ident/all             ::1\/128                 md5/g' /var/lib/pgsql/data/pg_hba.conf

# Enable and start PostgreSQL with systemd
systemctl start postgresql
systemctl enable postgresql

# Create opennms user with password and database
sudo -u postgres psql -c "CREATE USER opennms WITH PASSWORD 'opennms';"
sudo -u postgres psql -c "CREATE DATABASE opennms;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE opennms to opennms;"

# Create OpenNMS database configuration
printf '<?xml version="1.0" encoding="UTF-8"?>
<datasource-configuration>
  <connection-pool factory="org.opennms.core.db.C3P0ConnectionFactory"
    idleTimeout="600"
    loginTimeout="3"
    minPool="50"
    maxPool="50"
    maxSize="50" />

  <jdbc-data-source name="opennms"
                    database-name="opennms"
                    class-name="org.postgresql.Driver"
                    url="jdbc:postgresql://localhost:5432/opennms"
                    user-name="%s"
                    password="%s" />

  <jdbc-data-source name="opennms-admin"
                    database-name="template1"
                    class-name="org.postgresql.Driver"
                    url="jdbc:postgresql://localhost:5432/template1"
                    user-name="%s"
                    password="%s" />
</datasource-configuration>' opennms opennms opennms opennms \
  > /opt/opennms/etc/opennms-datasources.xml

# Initialize OpenNMS database schema
/opt/opennms/bin/install -dis

echo "org.opennms.rrd.storeByForeignSource=true" >> /opt/opennms/etc/opennms.properties

# Configure OpenNMS to use RRDtool
echo "org.opennms.rrd.strategyClass=org.opennms.netmgt.rrd.rrdtool.MultithreadedJniRrdStrategy" >> /opt/opennms/etc/rrd-configuration.properties
echo "org.opennms.rrd.interfaceJar=/usr/share/java/jrrd2.jar" >> /opt/opennms/etc/rrd-configuration.properties
echo "opennms.library.jrrd2=/usr/lib64/libjrrd2.so" >> /opt/opennms/etc/rrd-configuration.properties

# Enable and start OpenNMS with systemd
systemctl start opennms
systemctl enable opennms

firewall-cmd --zone=public --permanent --add-port=8980/tcp
