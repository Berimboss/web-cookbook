require 'poise'
require 'chef/resource'
require 'chef/provider'

module Mod
  class Resource < Chef::Resource
    include Poise
    provides :mod
    actions :apply
    attribute :name, name_attribute: true, kind_of: String
    attribute :path, kind_of: String, required: true
    attribute :root_dir, required: true, kind_of: String, default: '/usr/local/apache2/conf/modules/'
    attribute :local_cookbook, required: true, kind_of: String, default: 'web'
    attribute :stub, required: true, kind_of: String, default: 'module.conf.erb'
  end
  class Provider < Chef::Provider
    include Poise
    provides :mod
    def action_apply
      template "#{new_resource.root_dir}module-#{new_resource.name}.conf" do
        source new_resource.stub
        variables :context => {
          :name => new_resource.name,
          :path => new_resource.path
        }
        cookbook new_resource.local_cookbook
        sensitive true
      end
    end
  end
end
