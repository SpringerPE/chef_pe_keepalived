#
# Cookbook Name:: pe_keepalived
# Recipe:: databag
#
# Copyright (C) 2014 Jose Riguera, Springer SBM
# 

class ::Chef::Recipe
  include SPRpe
end

if node[:pe_keepalived][:bag_name]
  begin
    databag = node[:pe_keepalived][:data_bag]
    bagname = node[:pe_keepalived][:bag_name]
    environment = node[:pe_keepalived][:environment]
    set_databag('pe_keepalived', databag, bagname, environment)
  rescue
    Chef::Application.fatal!('Something was wrong while processing data_bag!', 1)
  end
end

