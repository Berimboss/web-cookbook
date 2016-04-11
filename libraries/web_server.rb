require 'poise'
require 'chef/resource'
require 'chef/provider'

module WebServer
  class Resource < Chef::Resource
    include Poise
    provides  :web_server
    actions   :build
    attribute :name, name_attribute: true, kind_of: String

  class Provider < Chef::Provider
    include Poise
    provides :web_server
    def action_build
      nil
    end
  end
end
