require 'poise'
require 'chef/resource'
require 'chef/provider'

module Forwarder
  class Resource < Chef::Resource
    include Poise
    provides :forwarder
    actions :apply
    attribute :name, name_attribute:true, kind_of: String
    attribute :root_dir, required: true, kind_of: String, default: '/usr/local/apache2/conf/forwarders/'
    attribute :local_cookbook, required: true, kind_of: String, default: 'web'
    attribute :stub, required: true, kind_of: String, default: 'forwarder.conf.erb'
    attribute :context, required: true, kind_of: Hash, default: {}
  end
  class Provider < Chef::Provider
    include Poise
    provides :forwarder
    def action_apply
      template "#{new_resource.root_dir}forwarder-#{new_resource.name}.conf" do
        source new_resource.stub
        variables :context => new_resource.context
        cookbook new_resource.local_cookbook
        sensitive true
      end
    end
  end
end
