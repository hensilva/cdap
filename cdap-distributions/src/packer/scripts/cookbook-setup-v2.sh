#!/bin/bash
#
# Copyright © 2015-2017 Cask Data, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

#
# Download cookbooks from Chef Supermarket
#

die() { echo $*; exit 1; }

export GIT_MERGE_AUTOEDIT=no

# Grab cookbooks using knife
# Due to https://issues.cask.co/browse/CDAP-13308, we can no longer use knife cookbook site install
# for cb in cdap idea maven openssh; do
#   knife cookbook site install $cb || die "Cannot fetch cookbook $cb"
# done

# Instead we must manually download and extract known good versions
knife supermarket download --force ambari || die "Cannot download cookbook ambari"
knife supermarket download --force apt || die "Cannot download cookbook apt"
knife supermarket download --force ark || die "Cannot download cookbook ark"
knife supermarket download --force build-essential || die "Cannot download cookbook build-essential"
knife supermarket download --force dpkg_autostart || die "Cannot download cookbook dpkg_autostart"
knife supermarket download --force hadoop || die "Cannot download cookbook hadoop"
knife supermarket download --force homebrew || die "Cannot download cookbook homebrew"
knife supermarket download --force idea || die "Cannot download cookbook idea"
knife supermarket download --force iptables || die "Cannot download cookbook iptables"
knife supermarket download --force java || die "Cannot download cookbook java"
knife supermarket download --force krb5 || die "Cannot download cookbook krb5"
knife supermarket download --force maven || die "Cannot download cookbook maven"
knife supermarket download --force mingw || die "Cannot download cookbook mingw"
knife supermarket download --force nodejs || die "Cannot download cookbook nodejs"
knife supermarket download --force ntp || die "Cannot download cookbook ntp"
knife supermarket download --force ohai || die "Cannot download cookbook ohai"
knife supermarket download --force openssh || die "Cannot download cookbook openssh"
knife supermarket download --force selinux || die "Cannot download cookbook selinux"
knife supermarket download --force seven_zip || die "Cannot download cookbook seven_zip"
knife supermarket download --force sysctl || die "Cannot download cookbook sysctl"
knife supermarket download --force ulimit || die "Cannot download cookbook ulimit"
knife supermarket download --force windows || die "Cannot download cookbook windows"
knife supermarket download --force yum || die "Cannot download cookbook yum"

# extract to /var/chef/cookbooks
for cb in `ls *.tar.gz`; do
  tar xf $cb -C /var/chef/cookbooks
  rm $cb
done

# Do not change HOME for cdap user
sed -i '/ home /d' /var/chef/cookbooks/cdap/recipes/sdk.rb

exit 0
