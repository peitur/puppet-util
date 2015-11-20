#!/usr/bin/sh

PUPPET_REPO_FILE="http://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm"

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
	echo "No NODE NAME"
	exit
fi

if [ ! ${PUPPET_NODE_TYPE} ]; then
	PUPPET_NODE_TYPE="node"
fi


YUM=$( which yum )
RPM=$( which rpm )

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
