#
# Cookbook Name:: pe_keepalived
# Recipe:: default
#
# Copyright (C) 2014 Jose Riguera, Springer SBM
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

# Loads the configuration from a databag
if node[:pe_keepalived][:data_bag]
   include_recipe 'pe_keepalived::databag'
end

# keepalived
include_recipe 'pe_keepalived::keepalived'


