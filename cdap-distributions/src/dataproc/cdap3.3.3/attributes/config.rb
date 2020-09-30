#
# Cookbook Name:: cdap
# Attribute:: config
#
# Copyright © 2013-2017 Cask Data, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Default: conf.chef
default['cdap']['conf_dir'] = 'conf.chef'
# Default: 4.3.4-1
default['cdap']['version'] = '4.3.4-1'
# cdap-site.xml
default['cdap']['cdap_site']['root.namespace'] = 'cdap'
# ideally we could put the macro '/${cdap.namespace}' here but this attribute is used elsewhere in the cookbook
default['cdap']['cdap_site']['hdfs.namespace'] = "/#{node['cdap']['cdap_site']['root.namespace']}"
default['cdap']['cdap_site']['hdfs.user'] = 'yarn'
default['cdap']['cdap_site']['kafka.seed.brokers'] = "#{node['fqdn']}:9092"
default['cdap']['cdap_site']['log.retention.duration.days'] = '7'
# COOK-85
if node['cdap']['version'].to_f < 4.0
  default['cdap']['cdap_site']['metadata.updates.kafka.broker.list'] = node['cdap']['cdap_site']['kafka.seed.brokers']
end
default['cdap']['cdap_site']['zookeeper.quorum'] = "#{node['fqdn']}:2181/#{node['cdap']['cdap_site']['root.namespace']}"
default['cdap']['cdap_site']['router.bind.address'] = node['fqdn']
default['cdap']['cdap_site']['router.server.address'] = node['fqdn']

# HDP 2.2+ support
hdp_version =
  if node.key?('hadoop') && node['hadoop'].key?('distribution_version')
    case node['hadoop']['distribution_version']
    when '2.2.0.0'
      '2.2.0.0-2041'
    when '2.2.1.0'
      '2.2.1.0-2340'
    when '2.2.4.2'
      '2.2.4.2-2'
    when '2.2.4.4'
      '2.2.4.4-16'
    when '2.2.6.0'
      '2.2.6.0-2800'
    when '2.2.6.3'
      '2.2.6.3-1'
    when '2.2.8.0'
      '2.2.8.0-3150'
    when '2.2.9.0'
      '2.2.9.0-3393'
    when '2.3.0.0'
      '2.3.0.0-2557'
    when '2.3.2.0'
      '2.3.2.0-2950'
    when '2.3.4.0'
      '2.3.4.0-3485'
    when '2.3.4.7'
      '2.3.4.7-4'
    when '2.3.6.0'
      '2.3.6.0-3796'
    when '2.4.0.0'
      '2.4.0.0-169'
    when '2.4.2.0'
      '2.4.2.0-258'
    when '2.4.3.0'
      '2.4.3.0-227'
    when '2.5.0.0'
      '2.5.0.0-1245'
    when '2.5.3.0'
      '2.5.3.0-37'
    when '2.5.5.0'
      '2.5.5.0-157'
    when '2.5.6.0'
      '2.5.6.0-40'
    when '2.6.0.3'
      '2.6.0.3-8'
    when '2.6.1.0'
      '2.6.1.0-129'
    when '2.6.2.0'
      '2.6.2.0-205'
    when '2.6.3.0'
      '2.6.3.0-235'
    when '2.6.4.0'
      '2.6.4.0-91'
    else
      node['hadoop']['distribution_version']
    end
  end

if node.key?('hadoop') && node['hadoop'].key?('distribution') && node['hadoop'].key?('distribution_version')
  if node['hadoop']['distribution'] == 'hdp' && node['hadoop']['distribution_version'].to_f >= 2.2 &&
     node['cdap']['version'].to_f >= 3.1
    default['cdap']['cdap_env']['opts'] = "${OPTS} -Dhdp.version=#{hdp_version}"
    default['cdap']['cdap_site']['app.program.jvm.opts'] = "-XX:MaxPermSize=128M ${twill.jvm.gc.opts} -Dhdp.version=#{hdp_version}"
    if node['cdap']['version'].to_f < 3.4
      default['cdap']['cdap_env']['spark_home'] = "/usr/hdp/#{hdp_version}/spark"
    end
  elsif node['hadoop']['distribution'] == 'iop'
    iop_version = node['hadoop']['distribution_version']
    default['cdap']['cdap_env']['opts'] = "${OPTS} -Diop.version=#{iop_version}"
    default['cdap']['cdap_site']['app.program.jvm.opts'] = "-XX:MaxPermSize=128M ${twill.jvm.gc.opts} -Diop.version=#{iop_version}"
  elsif node['cdap']['version'].to_f < 3.4 # CDAP 3.4 determines SPARK_HOME on its own (CDAP-5086)
    default['cdap']['cdap_env']['spark_home'] = '/usr/lib/spark'
  end
end
