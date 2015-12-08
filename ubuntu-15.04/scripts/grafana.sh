#!/bin/bash -e
# Script to bootstrap Grafana for OpenNMS

# Default build identifier set to snapshot
RELEASE="stable"
ERROR_LOG="grafana-install.log"
OPENNMS_HOME="/usr/share/opennms"
REQUIRED_USER="root"
USER=$(whoami)

REQUIRED_SYSTEMS="Ubuntu|Debian"
RELEASE_FILE="/etc/issue"

# Error codes
E_ILLEGAL_ARGS=126
E_BASH=127
E_UNSUPPORTED=128

# Test if system is supported
cat ${RELEASE_FILE} | grep -E ${REQUIRED_SYSTEMS} 1>/dev/null 2>>${ERROR_LOG}
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
installGrafanaRepo() {
  if [ ! -f /etc/apt/sources.list.d/grafana-${RELEASE}.list ]; then
    echo -n "Install Grafana Repository         ... "
    printf "deb https://packagecloud.io/grafana/${RELEASE}/debian/ wheezy main" > /etc/apt/sources.list.d/grafana-${RELEASE}.list
    checkError ${?}

    echo -n "Install Grafana Repository Key     ... "
    wget -q -O - https://packagecloud.io/gpg.key | sudo apt-key add -

    echo -n "Update repository                  ... "
    apt-get update 1>/dev/null 2>>${ERROR_LOG}
    checkError ${?}
  else
    echo "SKIP - file opennms-${RELEASE}.list already exist"
  fi
}

installGrafana() {
  echo -n "Install Grafana dependencies       ... "
  apt-get install -y grafana 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}

  echo -n "Enable Grafana on system start     ... "
  update-rc.d grafana-server defaults 95 10 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}

  echo -n "Start Grafana Server               ... "
  service grafana-server start 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}
}

installGrafana() {
  echo -n "Install Grafana dependencies       ... "
  apt-get install -y grafana 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}

  echo -n "Enable Grafana on system start     ... "
  update-rc.d grafana-server defaults 95 10 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}

  echo -n "Install OpenNMS Grafana Plugin     ... "
  apt-get install -y grafana-opennms-plugin 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}

  echo -n "Start Grafana Server               ... "
  service grafana-server start 1>/dev/null 2>>${ERROR_LOG}
  checkError ${?}
}

enableGrafanaBox() {
  echo -n "Enable Grafana Box                 ... "
  echo "org.opennms.grafanaBox.show=true" >> ${OPENNMS_HOME}/etc/opennms.properties
  checkError ${?}

  echo -n "Set Grafana Hostname               ... "
  echo "org.opennms.grafanaBox.hostname=localhost" >> ${OPENNMS_HOME}/etc/opennms.properties
  checkError ${?}

  echo -n "Set Grafana port                   ... "
  echo "org.opennms.grafanaBox.port=3000" >> ${OPENNMS_HOME}/etc/opennms.properties
  checkError ${?}

  echo -n "Set Grafana protocol               ... "
  echo "org.opennms.grafanaBox.protocol=http" >> ${OPENNMS_HOME}/etc/opennms.properties
  checkError ${?}
}

grafanaOnmsDataSource() {
  echo -n "Set Grafana OpenNMS data source    ... "
  curl 'http://admin:admin@localhost:3000/api/datasources' -X POST -H 'Content-Type:application/json;charset=UTF-8' --data-binary '{"name":"OpenNMS","type":"opennms","access":"proxy","url":"http://localhost:8980/opennms","isDefault":true,"basicAuth":true,"basicAuthUser":"admin","basicAuthPassword":"admin"}'
  checkError ${?}
}

installGrafanaRepo
installGrafana
enableGrafanaBox
grafanaOnmsDataSource
