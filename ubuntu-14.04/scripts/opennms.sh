#!/bin/bash -e
# Script to bootstrap a basic OpenNMS setup

# Default build identifier set to snapshot
RELEASE="stable"
ERROR_LOG="openms-install.log"
DB_USER="opennms"
DB_PASS="opennms"
OPENNMS_HOME="/usr/share/opennms"
REQUIRED_USER="root"
USER=$(whoami)
MIRROR="debian.opennms.eu"
ANSWER="No"

REQUIRED_SYSTEMS="Ubuntu|Debian"
RELEASE_FILE="/etc/issue"

# Error codes
E_ILLEGAL_ARGS=126
E_BASH=127
E_UNSUPPORTED=128

####
# Help function used in error messages and -h option
usage() {
  echo ""
  echo "Bootstrap OpenNMS basic setup on Debian based system."
  echo ""
  echo "-r: Set a release: stable | testing | snapshot"
  echo "    Default: ${RELEASE}"
  echo "-m: Set alternative mirror server for packages"
  echo "    Default: ${MIRROR}"
  echo "-h: Show this help"
}

showDisclaimer() {
  echo ""
  echo "This script installs OpenNMS on  your system. It will"
  echo "install  all  components necessary  to  run  OpenNMS."
  echo ""
  echo "The following components will be installed:"
  echo ""
  echo " - Oracle Java 8 JDK"
  echo " - PostgreSQL Server"
  echo " - OpenNMS Repositories"
  echo " - OpenNMS with core services and Webapplication"
  echo " - Initialize and bootstrapping the database"
  echo " - Start OpenNMS"
  echo ""
  echo "If you have OpenNMS already installed, don't use this"
  echo "script!"
  echo ""
  read -p "If you want to proceed, type YES: " ANSWER

  # Set bash to case insensitive
  shopt -s nocasematch

  if [[ "${ANSWER}" == "yes" ]]; then
    echo ""
    echo "Starting setup procedure ... "
    echo ""
  else
    echo ""
    echo "Your system is unchanged."
    echo "Thank you computing with us"
    echo ""
    exit ${E_BASH}
  fi

  # Set case sensitive
  shopt -u nocasematch
}

# Test if system is supported
cat ${RELEASE_FILE} | grep -E ${REQUIRED_SYSTEMS}  1>/dev/null 2>>${ERROR_LOG}
if [ ! ${?} -eq 0 ]; then
  echo ""
  echo "This is system is not a supported Ubuntu or Debian system."
  echo ""
  exit ${E_UNSUPPORTED}
fi

# Setting Postgres User and changing configuration files require
# root permissions.
if [ "${USER}" != "${REQUIRED_USER}" ]; then
  echo ""
  echo "This script requires root permissions to be executed."
  echo ""
  exit ${E_BASH}
fi

####
# The -r option is optional and allows to set the release of OpenNMS.
# The -m option allows to overwrite the package repository server.
while getopts r:m:h flag; do
  case ${flag} in
    r)
        RELEASE="${OPTARG}"
        ;;
    m)
        MIRROR="${OPTARG}"
        ;;
    h)
      usage
      exit ${E_ILLEGAL_ARGS}
      ;;
    *)
      usage
      exit ${E_ILLEGAL_ARGS}
      ;;
  esac
done

####
# Helper function which tests if a command was successful or failed
checkError() {
  if [ $1 -eq 0 ]; then
    echo "OK"
  else
    echo "FAILED"
    exit ${E_BASH}
  fi
}

####
# Install OpenNMS Debian repository for specific release
installOnmsRepo() {
  echo -n "Install OpenNMS Repository         ... "
  if [ ! -f /etc/apt/sources.list.d/opennms-${RELEASE}.list ]; then
    printf "deb http://${MIRROR} ${RELEASE} main\ndeb-src http://${MIRROR} ${RELEASE} main" \
           > /etc/apt/sources.list.d/opennms-${RELEASE}.list
    checkError ${?}

    echo -n "Install OpenNMS Repository Key     ... "
    wget -q -O - http://${MIRROR}/OPENNMS-GPG-KEY | sudo apt-key add -

    echo -n "Update repository                  ... "
    apt-get update 1>/dev/null 2>>${ERROR_LOG}
    checkError ${?}
  else
    echo "SKIP - file opennms-${RELEASE}.list already exist"
  fi
}

####
# Install the PostgreSQL database
installPostgres() {
  echo -n "Install PostgreSQL database        ... "
  apt-get install -y postgresql 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}
}

####
# Helper to request Postgres credentials to initialize the
# OpenNMS database.
queryDbCredentials() {
  echo -n "Create PostgreSQL credentials      ... "
  sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';" 1>/dev/null 2>>${ERROR_LOG}
  sudo -u postgres psql -c "ALTER USER ${DB_USER} WITH SUPERUSER;"  1>/dev/null 2>>${ERROR_LOG}
  sudo -u postgres psql -c "CREATE DATABASE opennms;" 1>/dev/null 2>>${ERROR_LOG}
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE opennms to ${DB_USER};" 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}
}

####
# Install the OpenNMS application from Debian repository
installOnmsApp() {
  echo -n "Oracle License and db install      ... "
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
  echo debconf shared/accepted-oracle-license-v1-1 seen true | /usr/bin/debconf-set-selections
  echo "opennmsdb opennms-db/noinstall string ok" | debconf-set-selections
  checkError ${?}

  echo -n "OpenNMS Database install           ... "
  apt-get install -y opennms-db 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}

  echo -n "OpenNMS Core Services install      ... "
  apt-get install -y opennms-server 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}

  echo -n "RRDtool package install            ... "
  apt-get install -y rrdtool 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}

  echo -n "OpenNMS JRRD2 package install      ... "
  apt-get install -y jrrd2 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}

  echo -n "OpenNMS Web Application install    ... "
  apt-get install -y opennms-webapp-jetty 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}

  echo -n "OpenNMS Contrib Package install    ... "
  apt-get install -y opennms-contrib 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}

  echo -n "OpenNMS XML Protocols install      ... "
  apt-get install -y opennms-plugin-protocol-xml 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}

  echo -n "OpenNMS Documentation install      ... "
  apt-get install -y opennms-doc 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}

  echo -n "Set RRDtool strategy               ... "
  echo "org.opennms.rrd.strategyClass=org.opennms.netmgt.rrd.rrdtool.MultithreadedJniRrdStrategy" >> ${OPENNMS_HOME}/etc/rrd-configuration.properties
  checkError ${?}

  echo -n "Set jrrd2 java library             ... "
  echo "org.opennms.rrd.interfaceJar=/usr/share/java/jrrd2.jar" >> ${OPENNMS_HOME}/etc/rrd-configuration.properties
  checkError ${?}

  echo -n "Set jrrd2 JNI library              ... "
  echo "opennms.library.jrrd2=/usr/lib/jni/libjrrd2.so" >> ${OPENNMS_HOME}/etc/rrd-configuration.properties
  checkError ${?}

  echo -n "OpenNMS setup Java environment     ... "
  ${OPENNMS_HOME}/bin/runjava -s 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}
}

####
# Generate OpenNMS configuration file for accessing the PostgreSQL
# Database with credentials
setCredentials() {
  echo ""
  echo -n "Generate data source config        ... "
  if [ -f "${OPENNMS_HOME}/etc/opennms-datasources.xml" ]; then
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
</datasource-configuration>' ${DB_USER} ${DB_PASS} ${DB_USER} ${DB_PASS} \
  > ${OPENNMS_HOME}/etc/opennms-datasources.xml
  checkError ${?}
  else
    echo "No OpenNMS configuration found in ${OPENNMS_HOME}/etc"
    exit ${E_ILLEGAL_ARGS}
  fi
}

####
# Initialize the OpenNMS database schema
initializeOnmsDb() {
  echo -n "Initialize OpenNMS                 ... "
  if [ ! -f $OPENNMS_HOME/etc/configured ]; then
    ${OPENNMS_HOME}/bin/install -dis 1>/dev/null 2>>${ERROR_LOG}
    checkError ${?}
  else
    echo "SKIP - already configured"
  fi
}

restartOnms() {
  echo -n "Starting OpenNMS                   ... "
  service opennms restart 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}
}

lockdownDbUser() {
  echo -n "PostgreSQL revoke super user role  ... "
  sudo -u postgres psql -c "ALTER ROLE ${1} NOSUPERUSER;" 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}
  echo -n "PostgreSQL revoke create db role   ... "
  sudo -u postgres psql -c "ALTER ROLE ${1} NOCREATEDB;" 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}
}

# Execute setup procedure
installOnmsRepo
installPostgres
queryDbCredentials
installOnmsApp
setCredentials
initializeOnmsDb
lockdownDbUser ${DB_USER}
restartOnms
