#!/usr/bin/sh

PUPPET_REPO_FILE="http://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm"
PUPPET_CONFIG="/etc/puppetlabs/puppet/puppet.conf"



if [ $1 ]; then
	PUPPET_NODE_NAME=$1
fi

echo "Override node name: ${PUPPET_NODE_NAME}"

## Specify (export) in user-data as script
## Need node name, PUPPET_NODE_NAME
## Need node type, PUPPET_NODE_TYPE

if [ $USER != "root" ]; then
	echo "Must be root to do this"
	exit
fi

if [ ! ${PUPPET_NODE_NAME} ]; then
	echo "No PUPPET_NODE_NAME"
	exit
fi

if [ ! ${PUPPET_SERVER_NAME} ]; then
	echo "No  PUPPET_SERVER_NAME"
	exit
fi

if [ ! ${PUPPET_NODE_TYPE} ]; then
	PUPPET_NODE_TYPE="common"
fi


YUM=$( which yum )
RPM=$( which rpm )
SYSTEMCTL=$( which systemctl )

if [ ! ${RPM} ]; then
	echo "Only supports RPM based (Red Hat) systems"
	exit
fi

if [ ! $( which wget ) ]; then
	echo "Installing wget fir dependency"
	$YUM install -y wget
fi

if [ ! $( which puppet) ]; then
	echo "Installing puppet-agent"
	$RPM -i ${PUPPET_REPO_FILE}
	$YUM install -y puppet-agent
else
	echo "Already have puppet-agent"
fi


if [ -f ${PUPPET_CONFIG} ];then
	$SYSTEMCTL enable puppet

cat > ${PUPPET_CONFIG}  <<EOL
# This file can be used to override the default puppet settings.
# See the following links for more details on what settings are available:
# - https://docs.puppetlabs.com/puppet/latest/reference/config_important_settings.html
# - https://docs.puppetlabs.com/puppet/latest/reference/config_about_settings.html
# - https://docs.puppetlabs.com/puppet/latest/reference/config_file_main.html
# - https://docs.puppetlabs.com/references/latest/confi

[main]
certname = ${PUPPET_NODE_NAME}
vardir = /opt/puppetlabs/server/data/puppetserver
logdir = /var/log/puppetlabs/puppetserver
rundir = /var/run/puppetlabs/puppetserver
pidfile = /var/run/puppetlabs/puppetserver/puppetserver.pid
codedir = /etc/puppetlabs/code

[agent]
	server = ${PUPPET_SERVER_NAME}
EOL

	$SYSTEMCTL start puppet
#	cat ${PUPPET_CONFIG}

fi

