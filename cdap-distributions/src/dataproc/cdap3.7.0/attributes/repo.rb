#
# Cookbook Name:: cdap
# Attribute:: repo
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

# major.minor
release = node['cdap']['version'][/^\d+\.\d+/]

# URL to repository
default['cdap']['repo']['apt_repo_url'] = "https://repository.cask.co/ubuntu/precise/amd64/cdap/#{release}"
default['cdap']['repo']['apt_components'] = ['cdap']
default['cdap']['repo']['yum_repo_url'] = "https://repository.cask.co/centos/6/x86_64/cdap/#{release}"
