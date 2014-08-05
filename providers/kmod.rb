def whyrun_supported?
  true
end


def load
  parameters = new_resource.parameters.join(' ')
  force = new_resource.force ? '-f' : ''
  execute "modprobe #{new_resource.name}" do
    command "modprobe #{force} -s #{new_resource.name} #{parameters}"
    not_if "lsmod | grep \"^#{new_resource.name} \""
  end
end

action :load do
  load
end


def unload
  force = new_resource.force ? '-f' : ''
  execute "rmmod #{new_resource.name}" do
    command "rmmod #{force} -s #{new_resource.name}"
    only_if "lsmod | grep \"^#{new_resource.name} \""
  end
end

action :unload do
  unload
end


action :install do
  if @current_resource.exists
    Chef::Log.info "#{@new_resource} already exists - nothing to do."
  else
    Chef::Log.info "Installing #{@new_resource}"
    load
    converge_by("Installing #{@new_resource}") do
      case node["platform_family"]
      when "debian"
        install_debian
      when "rhel"
        install_rh
      end
    end
  end
end


action :uninstall do
  if @current_resource.exists
    unload
    converge_by("Deleting #{@new_resource}") do
      case node["platform_family"]
      when "debian"
        uninstall_debian
      when "rhel"
        uninstall_rh
      end
    end
  else
    Chef::Log.info "#{@current_resource} doesn't exist - can't delete."
  end
end


def install_debian
    if new_resource.file_modules || !::Dir.exist?('/etc/modules-load.d')
      ruby_block "install_debian" do
        block do
          parameters = new_resource.parameters.join(' ')
          file = Chef::Util::FileEdit.new("/etc/modules")
          file.insert_line_if_no_match(/ #{new_resource.name} /, "#{new_resource.name} #{parameters}")
          file.write_file
        end
        only_if "lsmod | grep \"^#{new_resource.name} \""
      end
    else
      parameters = new_resource.parameters.join(' ')
      file "/etc/modules-load.d/#{new_resource.name}" do
        action :create_if_missing
        content "# Created by chef\n#{new_resource.name} #{parameters}\n"
        backup false
        owner "root"
        group "root"
        mode 0644
        only_if "lsmod | grep \"^#{new_resource.name} \""
      end
    end
end

def install_rh
    parameters = new_resource.parameters.join(' ')
    file "/etc/sysconfig/modules/#{new_resource.name}.modules" do
        action :create_if_missing
        content "#!/bin/sh\n# Created by chef\nexec /sbin/modprobe -s #{new_resource.name} #{parameters} >/dev/null 2>&1\n"
        backup false
        owner "root"
        group "root"
        mode 0755
        only_if "lsmod | grep \"^#{new_resource.name} \""
    end
end


def uninstall_debian
   if new_resource.file_modules || !::Dir.exist?('/etc/modules-load.d')
     ruby_block "uninstall_debian" do
       block do
         file = Chef::Util::FileEdit.new("/etc/modules")
         file.search_file_delete_line(/^#{new_resource.name}.*$/)
         file.write_file
       end
     end
   else
      file "/etc/modules-load.d/#{new_resource.name}" do
        action :delete
        backup false
      end
   end
end

def uninstall_rh
   file "/etc/sysconfig/modules/#{new_resource.name}.modules" do
        action :delete
        backup false
   end
end


def load_current_resource
  @current_resource = Chef::Resource::PeKeepalivedKmod.new(@new_resource.name)
  begin
    @current_resource.name(@new_resource.name)
    @current_resource.parameters(@new_resource.parameters)
  rescue
    Chef::Log.debug("Cannot find #{new_resource} in the swarm")
  end
  name = @current_resource.name
  if system("lsmod | grep \"^#{name} \"")
    @current_resource.exists = true
  end
end

