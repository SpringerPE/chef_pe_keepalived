name             'pe_keepalived'
maintainer       'Platform Engineering'
maintainer_email 'platform-engineering@springer.com'
license          'Apache 2.0'
description      'Installs/Configures keepalived'
long_description 'Installs/Configures keepalived'
version          '0.1.0'

%w{ debian ubuntu centos redhat  }.each do |os|
  supports os
end

depends 'sysctl', '~> 0.6.0'
