require 'poise'
require 'chef/resource'
require 'chef/provider'

module Configuration
  class Resource < Chef::Resource
    include Poise
    provides  :configuration
    actions   :apply, :purge

    attribute :name, name_attribute: true, kind_of: String
    attribute :root_dir, required: true, default: '/usr/local/apache2/conf/'
    attribute :stub, required: true, default: 'httpd.conf.erb'
    attribute :local_cookbook, kind_of:String, default: 'web'
    attribute :context, required: true, default: {}
    attribute :includes, kind_of: Array, default: %w{globals/* ports/* modules/* forwarders/* statics/*}
  end
  class Provider < Chef::Provider
    include Poise
    provides :configuration
    def given_the_givens
      directory new_resource.root_dir do
        recursive true
      end
      directory "#{new_resource.root_dir}modules/" do
        recursive true
      end
      directory "#{new_resource.root_dir}forwarders/" do
        recursive true
      end
      directory "#{new_resource.root_dir}statics/" do
        recursive true
      end
      directory "#{new_resource.root_dir}globals/" do
        recursive true
      end
      directory "#{new_resource.root_dir}ports/" do
        recursive true
      end
      yield
    end
    def action_apply
      given_the_givens do
        template "#{new_resource.root_dir}httpd.conf" do
          source new_resource.stub
          variables :context => {
            :includes => new_resource.includes
          }
          cookbook new_resource.local_cookbook
          sensitive true
        end
      end
    end
    def action_purge
      bash "purge all configurations" do
        cwd Chef::Config[:file_cache_path]
        code <<-EOH
        rm -rf #{new_resource.root_dir}*
        EOH
      end
    end
  end
end
