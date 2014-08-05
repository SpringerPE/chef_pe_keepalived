#
# Cookbook Name:: pe_keepalived
# Recipe:: keepalived
#
# Copyright (C) 2014 Jose Riguera, Springer SBM
# 

class ::Chef::Recipe
  include SPRpe
end

package "keepalived"

dr = false
nat = false
lvs_id = net_dev(node.default[:pe_keepalived][:lvs_id_device])
virtual_device = node.default[:pe_keepalived][:virtual_device]
node.default[:pe_keepalived][:sync_groups].each_pair do |group, value|
  value[:instances].each_pair do |name, instance|
    virtual_ipaddress = []
    priority = 0
    state = 'BACKUP'
    if instance[:virtualserver]
      instance[:virtualserver].each_pair do |virtual, vserver|
          vip = virtual.split(':')[0] 
          virtual_ipaddress.push(vip)
          if vserver
            maxprio = 0
            myprio = 0
            vserver[:servers].each_pair do |server, sparm|
              prio = sparm.has_key?("priority") ? sparm[:priority] : 0
              ip = server.split(':')[0]
              port = server.split(':')[1]
              dev = dev_addr(ip, 'inet')
              if dev
                myprio = prio              
              else
                maxprio = (maxprio < prio)? prio : maxprio
              end
              has_check = false
              ['HTTP_GET', 'SSL_GET', 'TCP_CHECK', 'SMTP_CHECK', 'MISC_CHECK'].each do |t|
                if sparm.include?(t)
                  has_check = true
                  break
                end
              end
              if !has_check && node[:pe_keepalived][:auto_check]
                proto = vserver.has_key?('protocol') ? vserver[:protocol].downcase : 'tcp'
                sparm[:TCP_CHECK] = { :connect_timeout => 3 } if proto == 'tcp'
              end
            end
            state = maxprio < myprio ? 'MASTER' : 'BACKUP'
            priority = myprio > priority ? myprio : priority
            if vserver.has_key?('lb_kind')
              if vserver[:lb_kind].downcase == 'dr'
                if !node[:pe_keepalived][:static_ipaddress].include?(vip)
	          node.default[:pe_keepalived][:static_ipaddress].push("#{vip} dev #{virtual_device}")
                end
	        dr = true
              else
	        nat = true
              end
            end
          end
      end
    end
    if instance.has_key?("master")
      dev = dev_addr(instance[:master], 'inet')
      state = dev ? 'MASTER' : 'BACKUP'
      priority = dev ? 200 : 100
    end
    instance[:state] = state
    instance[:priority] = priority
    if !instance.has_key?("virtual_ipaddress")
      instance[:virtual_ipaddress] = virtual_ipaddress
    end
    ip = instance[:virtual_ipaddress][0]
    instance[:virtual_router_id] = ip.split('.')[3]
    if !instance.has_key?("auth_pass")
      instance[:auth_type] = 'PASS'
      instance[:auth_pass] = ip
    end
  end 
end

include_recipe 'sysctl::default'

# DR options
if dr
  Chef::Log.info("Preparing DR parameters on #{virtual_device} ...")
  if node.default[:pe_keepalived][:virtual_device].start_with?('dummy')
    number = Integer(node.default[:pe_keepalived][:virtual_device][5]) + 1
    pe_keepalived_kmod 'dummy' do
    	action :install
        parameters ["numdummies=#{number}"]
    end
  end
  sysctl_param "net.ipv4.conf.#{virtual_device}.arp_ignore" do
      value 1
  end
  sysctl_param "net.ipv4.conf.#{virtual_device}.arp_announce" do
      value 2
  end
end

# Nat options
if nat
  Chef::Log.info("Enabling ip_forward for NAT ...")
  sysctl_param "net.ipv4.ip_forward" do
      value 1
  end
end

# ip nonlocal_bind
if node.default[:pe_keepalived][:nonlocal_bind]
  sysctl_param "net.ipv4.ip_nonlocal_bind" do
      value 1
  end
end

# keepalived template
template "keepalived.conf" do
  path "/etc/keepalived/keepalived.conf"
  source "etc/keepalived/keepalived.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables({
    :lvs_id =>  lvs_id
  })
end

service "keepalived" do
  supports :restart => true
  action [:enable, :start]
  subscribes :restart, "template[keepalived.conf]"
end

