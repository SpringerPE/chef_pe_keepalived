# pe_keepalived cookbook

Cookbook to setup keepalived clusters (for HA and load balancing) in a flexible way. 
It supports all keepalived parameters and it can read all of them from a databag.

## Supported Platforms

 * Debian
 * Ubuntu
 * Centos
 * RedHat

## Attributes

To can define the attributes, or use a databag to read and setup all of them.
For instance, here you see the attribute file of this cookbook:

```
### Main attributes
default[:pe_keepalived][:data_bag] = 'network'
default[:pe_keepalived][:bag_name] = 'keepalived'
default[:pe_keepalived][:environment] = node[:chef_environment] ? node[:chef_environment] : "_default"

### Options
default[:pe_keepalived][:lvs_id_device] = 'eth0'     # 'lvs_id' will be the ip of that device
default[:pe_keepalived][:nonlocal_bind] = true       # allow binding to a non defined IP
default[:pe_keepalived][:virtual_device] = 'dummy0'  # or 'lo' to avoid loading dummy kernel module
default[:pe_keepalived][:auto_check] = true          # if no TCP checks are defined, they will be created.

### Keepalived attributes (see manual)
default[:pe_keepalived][:global] = {         # keepalived 'global_defs' parameters
    :notification_emails => ['root'],
    :email_from => "keepalived@#{node[:fqdn]}",
    :smtp_server => 'localhost'
}
# Usually empty. They will be filled automatically
default[:pe_keepalived][:static_ipaddress] = []
default[:pe_keepalived][:static_routes] = []
# Main configuration (see manual)
default[:pe_keepalived][:sync_groups] = {    # example configuration with Haproxy (commented parameters are
#                                            # not necessary.
#    'haproxy' => {                          # keepalived 'vrrp_sync_group' section parameters.
#        #:notify_backup => "script1",
#        #:notify_fault => "script2",
#        #:notify_master => "script3",
#        :instances => {
#            'web' => {                      # keepalived 'vrrp_instance' section parameters except :master,
#                                            # :virtual_ipaddress and :scripts.
#                :master => '23.23.23.23',   # cookbook parameter to define which real server will be the master
#                                            # not necessary if priority is defined in each real server.
#                'interface' => 'eth1',      # interface were the virtual IP will be available.
#                #'smtp_alert' => true,
#                #:virtual_ipaddress => ['12.12.12.12'],   # if not virtualserver, this entry (and :master) will
#                                                          # be used. Useful with Haproxy.
#                #'auth_type' => 'PASS',
#                #'auth_pass' => 'dsfasfadfad',            # if no password is defined, it will be filled with 
#                                                          # the 1st IP of :virtual_ipaddress (or virtualserver).
#                :scripts => {                             # scripts to manage the services.
#                    'chk_haproxy'=> {
#                        'script' => "killall -0 haproxy",
#                        'interval' => 2,
#                        'weight' => 2
#                     },
#                },
#                'virtualserver' => {                      # definition of the services with format 'vip:port'.
#                    '13.13.13.13:80' => {                 # it can be an empty hash if no :virtual_ipaddress.
#                          #'delay_loop' => 30,            # keepalived 'virtual_server' parameters.
#                          #'lb_algo' => 'rr',
#                          #'lb_kind' => 'DR',
#                          #'persistence_timeout' => '60',
#                          #'protocol' => 'TCP',
#                          #'servers' => {                 # keepalived 'real_server' parameters, except
#                                                          # :priority. 
#                              #'23.23.23.23:80' => {
#                                  #:priority' => 200,     # value to work out the master if no :master defined.
#                                  #'weight' => 20,
#                                  #'HTTP_GET' => {
#                                      #'url' => {
#                                          #'path' => "/testurl2/test.jsp",
#                                          #'digest' => "640205b7b0fc66c1ea91c463fac6334c",
#                                      #},
#                                      #'connect_timeout' => 3,
#                                      #'nb_get_retry' => 3,
#                                      #'delay_before_retry' => 2
#                                  #}                               
#                              #},
#                              #'24.24.24.24:80' => {      # if no checks are defined, it will create a TCP
#                                                          # on the port.
#                                  #'weight' => 30                      
#                              #}
#                          #}
#                    }
#                }
#            }
#        }
#    }
}

```
The structure of the keepalived configuration is almost its own configuration, except the attributes defined with 
`:` like  `:master`, `:scripts`, etc

You can see all the keepalived parameters http://www.keepalived.org/documentation.html

## Usage

The easy way is just use a databag to define a cluster of servers. For example, to define a basid Haproxy HA 
configuration:
```json
{
    "id": "keepalived",
    "_default": {
        "sync_groups": {
            "haproxy": {
                "instances": {
                    "web": {
                        "master": "10.10.10.20", 
                        "interface": "eth1",
                        "virtual_ipaddress": ["10.10.10.50"],
                        "scripts": {          
                            "chk_haproxy": {
                                "script": "killall -0 haproxy",
                                "interval": "2",
                                "weight": "2"
                            }
                        }
                    }
                }
            }
        }
    }
}
```

This will generate a configuration to get Haproxy running on 10.10.10.50, with the master server in 10.10.10.20, all 
the rest serverwill be slaves.


To apply the cookbook just include `pe_keepalived` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[pe_keepalived::default]"
  ]
}
```

# Author

Author:: Jose Riguera (Springer SBM) (<jose.riguera@springer.com>)
