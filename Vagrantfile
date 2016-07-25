# -*- mode: ruby -*-
# vi: set ft=ruby :

# The private network IP of the VM. You will use this IP to connect to OpenShift.
PUBLIC_ADDRESS="10.1.2.2"

# Number of virtualized CPUs
VM_CPU = ENV['VM_CPU'] || 3

# Amount of available RAM
VM_MEMORY = ENV['VM_MEMORY'] || 4096

# Validate required plugins
REQUIRED_PLUGINS = %w(vagrant-service-manager vagrant-registration)
errors = []

# Location of Admin Kubeconfig
KUBECONFIG="KUBECONFIG=/var/lib/openshift/openshift.local.config/master/admin.kubeconfig"

def message(name)
  "#{name} plugin is not installed, run `vagrant plugin install #{name}` to install it."
end
# Validate and collect error message if plugin is not installed
REQUIRED_PLUGINS.each { |plugin| errors << message(plugin) unless Vagrant.has_plugin?(plugin) }
unless errors.empty?
  msg = errors.size > 1 ? "Errors: \n* #{errors.join("\n* ")}" : "Error: #{errors.first}"
  fail Vagrant::Errors::VagrantError.new, msg
end

Vagrant.configure(2) do |config|
  config.vm.box = "cdkv2"

  config.vm.provider "virtualbox" do |v, override|
    v.memory = VM_MEMORY
    v.cpus   = VM_CPU
    v.customize ["modifyvm", :id, "--ioapic", "on"]
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  config.vm.provider "libvirt" do |v, override|
    v.memory = VM_MEMORY
    v.cpus   = VM_CPU
    v.driver = "kvm"
  end

  config.vm.network "private_network", ip: "#{PUBLIC_ADDRESS}"

  if ENV.has_key?('SUB_USERNAME') && ENV.has_key?('SUB_PASSWORD')
    config.registration.username = ENV['SUB_USERNAME']
    config.registration.password = ENV['SUB_PASSWORD']
  end

  config.servicemanager.services = "docker"

  config.vm.provision "shell", run: "always", inline: <<-SHELL
    systemctl enable openshift 2>&1
    systemctl start openshift
  SHELL
  
  config.vm.provision "shell", inline: <<-SHELL   
  
  KUBECONFIG="KUBECONFIG=/var/lib/openshift/openshift.local.config/master/admin.kubeconfig"
  SUBDOMAIN=$(grep subdomain /var/lib/openshift/openshift.local.config/master/master-config.yaml | awk '{ print $2 }')

  sudo curl -o /tmp/metrics-deployer.yaml https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_examples/files/examples/v1.2/infrastructure-templates/enterprise/metrics-deployer.yaml

  sudo ${KUBECONFIG} oc create -n openshift-infra -f - <<API
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: metrics-deployer
    secrets:
    - name: metrics-deployer
API

  sudo ${KUBECONFIG} oadm policy add-role-to-user edit system:serviceaccount:openshift-infra:metrics-deployer -n openshift-infra

  sudo ${KUBECONFIG} oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:openshift-infra:heapster -n openshift-infra

  sudo ${KUBECONFIG} oc secrets new metrics-deployer nothing=/dev/null -n openshift-infra

  sudo ${KUBECONFIG} oc process -f /tmp/metrics-deployer.yaml -v HAWKULAR_METRICS_HOSTNAME=hawkular-metrics.${SUBDOMAIN},CASSANDRA_PV_SIZE=3Gi,USE_PERSISTENT_STORAGE=true > /tmp/metrics-cdk.yaml

  sudo ${KUBECONFIG} oc create -n openshift-infra -f /tmp/metrics-cdk.yaml

  sudo sed -i "s|metricsPublicURL: \\\"\\\"|metricsPublicURL: \\\"https://hawkular-metrics.${SUBDOMAIN}/hawkular/metrics\\\"|"  /var/lib/openshift/openshift.local.config/master/master-config.yaml

  sudo systemctl restart openshift

  sudo rm -rf /tmp/metrics.yaml /tmp/cdk-metrics.yaml
     
  SHELL

  config.vm.provision "shell", run: "always", inline: <<-SHELL
    echo
    echo "Successfully started and provisioned VM with #{VM_CPU} cores and #{VM_MEMORY} MB of memory."
    echo "To modify the number of cores and/or available memory set the environment variables"
    echo "VM_CPU respectively VM_MEMORY."
    echo
    echo "You can now access the OpenShift console on: https://#{PUBLIC_ADDRESS}:8443/console"
    echo
    echo "To use OpenShift CLI, run:"
    echo "$ vagrant ssh"
    echo "$ oc login #{PUBLIC_ADDRESS}:8443"
    echo
    echo "Configured users are (<username>/<password>):"
    echo "openshift-dev/devel"
    echo "admin/admin"
    echo
    echo "If you have the oc client library on your host, you can also login from your host."
    echo
  SHELL
end
