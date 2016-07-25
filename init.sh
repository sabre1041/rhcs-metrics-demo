#!/bin/sh 
SCRIPT_BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DEMO="OpenShift Container Platform Metrics Demo"
AUTHORS="Andrew Block, Eric D. Schabell"
PROJECT="git@github.com:redhatdemocentral/rhcs-metrics-demo.git"
OPENSHIFT_USER=openshift-dev
OPENSHIFT_PWD=devel
METRICS_PROJECT=rhcs-metrics-demo


# wipe screen.
clear 

# make some checks first before proceeding.	
command -v oc -v >/dev/null 2>&1 || { echo >&2 "OpenShift command line tooling is required but not installed yet... download here:
https://access.redhat.com/downloads/content/290"; exit 1; }

echo "OpenShift commandline tooling is installed..."

echo 
echo "Brining up Red Hat Container Development Kit..."
echo
vagrant up

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during 'vagrant up' command!
	exit
fi

echo 
echo "Logging in to OpenShift as $OPENSHIFT_USER..."
echo
oc login 10.1.2.2:8443 --password=$OPENSHIFT_PWD --username=$OPENSHIFT_USER

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during 'oc login' command!
	exit
fi
						
echo
echo "Creating a new project ${METRICS_PROJECT}..."
echo
oc new-project ${METRICS_PROJECT} --description='Project to demonstrate the metrics capabilities of the OpenShift platform' --display-name='OpenShift Metrics Demo'

echo
echo "Creating a new application..."
echo
oc new-app cakephp-example
															
if [ $? -ne 0 ]; then
	echo
	echo Error occurred during 'oc new-app' command!
	exit
fi

echo
echo "===================================================================="
echo "=                                                                  ="
echo "=  Login to OpenShift to explore the demo :                        ="
echo "=                                                                  ="
echo "=  https://10.1.2.2:8443                                           ="
echo "=                                                                  ="
echo "=  [ u:${OPENSHIFT_USER} / p:${OPENSHIFT_PWD} ]                                   ="
echo "=                                                                  ="
echo "===================================================================="

