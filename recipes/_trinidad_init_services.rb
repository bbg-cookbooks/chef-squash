#
# Cookbook Name:: squash
# Recipe:: _trinidad_init_services
# Author:: Sam Cooper <scooper@bluebox.net>
#
# Copyright 2013, Blue Box Group, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# METHODOLOGY

# the trinidad_init_services gem creates a trinidad init script for you:
# https://github.com/trinidad/trinidad_init_services

# This recipe used that gem to create an initial /etc/init.d/trinidad
# that was then templatized
# It doesn't run the  trinidad_init_service command on it's own.

# it also uses the embedded source to build the jsvc binary


node.default.trinidad.log_dir = "/var/log/trinidad/"
node.default.trinidad.pid_dir = "/var/run/trinidad/"

directory node.trinidad.log_dir do
  owner node.squash.user
  group node.squash.group
end

directory node.trinidad.pid_dir do
  owner node.squash.user
  group node.squash.group
end

# jsvc gets used by the init script
execute "compile_jsvc" do
  command "RBENV_VERSION=#{node.squash.jruby.version} jruby -e \"require 'trinidad_init_services'; _c = Trinidad::InitServices::Configuration.new; _c.send(:compile_jsvc, '/usr/local/src')\""
  environment ({ 'HOME' => '/root' })
  creates "/usr/local/src/jsvc-unix-src/jsvc"
  notifies :run, "execute[cp_jsvc]"
end

execute "cp_jsvc" do
  command "cp /usr/local/src/jsvc-unix-src/jsvc /usr/bin/jsvc"
  action :nothing
end

template "/etc/init.d/trinidad" do
  source "trinidad_init"
  mode "0755"
  variables :run_user => node.squash.user,
  :app_path => node.squash.current_dir,
  :pid_file => "#{node.default.trinidad.pid_dir}/trinidad.pid",
  :log_file => "#{node.default.trinidad.log_dir}/trinidad.log",
  :jruby => node.squash.jruby.version
end

service "trinidad" do
  action [ :enable, :start ]
end

# start is failing, not sure what's up, ergo this
execute "start_trinidad" do
  command "service trinidad start"
  not_if "ps aux | grep -v grep | grep trinidad"
end
