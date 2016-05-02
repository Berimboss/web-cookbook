require 'poise'
require 'chef/resource'
require 'chef/provider'

module Static
  class Resource < Chef::Resource
    include Poise
    provides :static
    actions :apply
    attribute :name, name_attribute:true, kind_of: String
    attribute :mode, kind_of: String, required: true, default: '755'
    attribute :user, kind_of: String, required: true, default: 'root'
    attribute :group, kind_of: String, required: true, default: 'root'
    attribute :root_dir, required: true, kind_of: String, default: '/usr/local/apache2/conf/statics/'
    attribute :local_cookbook, required: true, kind_of: String, default: 'poise-web'
    attribute :stub, required: true, kind_of: String, default: 'static.conf.erb'
    attribute :context, required: true, kind_of: Hash, default: {}
  end
  class Provider < Chef::Provider
    include Poise
    provides :static
    def action_apply
      template "#{new_resource.root_dir}static-#{new_resource.name}.conf" do
        source new_resource.stub
        variables :context => new_resource.context
        cookbook new_resource.local_cookbook
      end
    end
  end
end
