actions :load, :install, :unload, :uninstall 
default_action :install

attribute :name, :kind_of => String, :name_attribute => true, :required => true
attribute :parameters, :kind_of => Array, :default => []

attribute :force, :kind_of => [TrueClass, FalseClass], :default => false
attribute :file_modules, :kind_of => [TrueClass, FalseClass], :default => false

def initialize(*args)
  super
  @resource_name = :kmod
  @action = :install
end


attr_accessor :exists
