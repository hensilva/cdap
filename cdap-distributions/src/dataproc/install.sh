#!/bin/bash
# based on cdap/cdap-distributions/src/emr/install.sh
# some changes to allow installation on dataproc (similar to EMR)
# lots of workarounds used here
# USE AT YOUR OWN RISK

CDAP_BRANCH=release/6.2
CDAP_VERSION=6.2.0-1
CHEF_VERSION=14.15.6 # 14.15.6 or 13.12.14
CHEF_COOKBOOK=3.3.3
EXPLORE_ENABLED='false'
SERVICE_DELAY=240
DASHBOARD_PORT=8000
CDAP_APT_REPO_URL=https://repository.cdap.io/ubuntu/precise/amd64/cdap/6.2
GIT_REPO=https://github.com/hensilva/cdap.git 
SPARK_COMPAT=spark2_2.11

__tmpdir="/tmp/cdap_install_temp"
__ipaddr=$(hostname -i)
__gitdir="${__tmpdir}/cdap"
__packerdir="${__gitdir}/cdap-distributions/src/packer/scripts"
__cdap_site_dir="${__gitdir}/cdap-distributions/src/dataproc"

test -d ${__tmpdir} && sudo rm -rf ${__tmpdir}

# Install git
sudo apt-get install -y git

# Install chef
mkdir -p ${__tmpdir}
curl -L -o ${__tmpdir}/install.sh https://www.chef.io/chef/install.sh && sudo bash ${__tmpdir}/install.sh -v ${CHEF_VERSION}

# Clone CDAP repo
git clone --depth 1 --branch ${CDAP_BRANCH} ${GIT_REPO} ${__gitdir}

# Setup cookbook repo
test -d /var/chef/cookbooks && sudo rm -rf /var/chef/cookbooks
sudo ${__packerdir}/cookbook-dir.sh

# Install cookbooks via knife
mkdir -p ${__tmpdir}/cookbook-download
cd ${__tmpdir}/cookbook-download
sudo chmod +x ${__packerdir}/cookbook-setup.sh
sudo ${__packerdir}/cookbook-setup.sh

# Copy recipe workarounds
sudo cp -p ${__cdap_site_dir}/cdap${CHEF_COOKBOOK}/recipes/*.rb /var/chef/cookbooks/cdap/recipes

# Create chef json configuration
sed \
  -e "s#{{DASHBOARD_PORT}}#${DASHBOARD_PORT}#" \
  -e "s#{{CDAP_VERSION}}#${CDAP_VERSION}#" \
  -e "s#{{CDAP_APT_REPO_URL}}#${CDAP_APT_REPO_URL}#" \
  -e "s#{{EXPLORE_ENABLED}}#${EXPLORE_ENABLED}#" \
  -e "s#{{ROUTER_IP_ADDRESS}}#${__ipaddr}#" \
  -e "s#{{SPARK_COMPAT}}#${SPARK_COMPAT}#" \
  ${__cdap_site_dir}/cdap-conf.json > ${__tmpdir}/generated-conf.json

# Install/Configure CDAP
sudo chef-solo -o 'recipe[cdap::fullstack]' -j ${__tmpdir}/generated-conf.json

### TODO: Temporary Hack to workaround CDAP-4089
sudo rm -f /opt/cdap/kafka/lib/log4j.log4j-1.2.14.jar

### TODO: Ensure Kafka directory is available until caskdata/cdap_cookbook#187 is merged and released
sudo su - -c "mkdir -p /mnt/cdap/kafka-logs && chown -R cdap /mnt/cdap"

# Start CDAP Services
for i in /etc/init.d/cdap-*; do
  __svc=$(basename ${i})
  echo ${__svc}
  sudo service ${__svc} start
done
