# Install OpenNMS repository
printf 'deb http://%s %s main\ndeb-src http://%s %s main' "debian.opennms.org" "stable" "debian.opennms.org" "stable" \
> /etc/apt/sources.list.d/opennms-stable.list

# Install GPG Key
wget -q -O - http://"debian.opennms.org"/OPENNMS-GPG-KEY | sudo apt-key add -
apt-get update

# Install PostgreSQL database
apt-get install -y postgresql

# Create opennms database user and password with permissions
sudo -u postgres psql -c "CREATE USER opennms WITH PASSWORD 'opennms';"
sudo -u postgres psql -c "ALTER USER opennms WITH SUPERUSER;"
sudo -u postgres psql -c "CREATE DATABASE opennms;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE opennms to opennms;"

# Accept Oracle license agreements
echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | /usr/bin/debconf-set-selections
echo "opennmsdb opennms-db/noinstall string ok" | debconf-set-selections

# Install OpenNMS with RRDtool
apt-get install -y jrrd2
apt-get install -y opennms-db
apt-get install -y opennms-server
apt-get install -y opennms-webapp-jetty
apt-get install -y opennms-contrib
apt-get install -y opennms-plugin-protocol-xml
apt-get install -y opennms-doc

# Enable RRDtool instead of JRobin
echo "org.opennms.rrd.strategyClass=org.opennms.netmgt.rrd.rrdtool.MultithreadedJniRrdStrategy" >> /usr/share/opennms/etc/opennms.properties.d/rrd-configuration.properties
echo "org.opennms.rrd.interfaceJar=/usr/share/java/jrrd2.jar" >> /usr/share/opennms/etc/opennms.properties.d/rrd-configuration.properties
echo "opennms.library.jrrd2=/usr/lib/jni/libjrrd2.so" >> /usr/share/opennms/etc/opennms.properties.d/rrd-configuration.properties

# Set Java for environment for OpenNMS
/usr/share/opennms/bin/runjava -s

# Generate OpenNMS database configuration
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
> /usr/share/opennms/etc/opennms-datasources.xml

# Initialize OpenNMS database schema
/usr/share/opennms/bin/install -dis

# Enable OpenNMS on system boot and start
update-rc.d opennms defaults
service opennms -Q start

# Lockdown database user
sudo -u postgres psql -c "ALTER ROLE opennms NOSUPERUSER;"
sudo -u postgres psql -c "ALTER ROLE opennms NOCREATEDB;"
