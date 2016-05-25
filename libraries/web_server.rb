require 'poise'
require 'chef/resource'
require 'chef/provider'
require_relative 'apache'

module WebServer
  class Resource < Chef::Resource
    include Poise
    provides  :web_server
    actions   :build

    # name triggers implementation strategy
    attribute :name, name_attribute: true, kind_of: String
    attribute :resource_deps, default: true
    attribute :build_essential, default: 'build-essential'
    attribute :local_cookbook, kind_of:String, default: 'poise-web'
    attribute :install_deps, default: true
    # General Web Server Interfaces
    # version can apply to any web server version
    attribute :httpd_version, kind_of: String, default: '2.4.20'
    # Apache interfaces
    attribute :apr_version, kind_of: String, default: '1.5.2'
    attribute :apr_util_version, kind_of: String, default: '1.5.4'
    attribute :apr_iconv_version, kind_of: String, default: '1.2.1'
    attribute :pcre_version, kind_of: String, default: '8.38'
    attribute :ssl_version, kind_of: String, default: '1.0.2g'
    attribute :ldap_version, kind_of: String, default: '2.4.44'
    # flags for apache compilation requiring a value
    attribute :prefix, kind_of: String, default: '/usr/local/apache2/'
    attribute :configure, kind_of: Array, default: [
      {:key => '--prefix', :val =>'/usr/local/apache2'},
      {:key => '--with-mpm', :val =>'event'},
      {:key => '--with-pcre', :val =>'/usr/local/bin/pcre-config'},
      {:key => '--enable-mods-shared', :val =>'all'}
    ]
    # flags for apache compilation that do not require a value
    attribute :configure_list, kind_of: Array, default: [
      '--enable-ssl',
      '--enable-so',
      '--with-included-apr'
    ]
    # name of the template that builds apache
    attribute :apache_build_template, kind_of: String, default: 'apache_build_stub.erb'
    #Packaging interfaces
    # Use fpm to make this a package?
    attribute :package, kind_of: [TrueClass, FalseClass], default: true
    attribute :package_dir, kind_of: String, default: '/usr/local/apache2/'
    # Ship the package to an s3 bucket?
    attribute :s3_upload, kind_of: [TrueClass, FalseClass], default: false
    attribute :package_format, kind_of: String, default: 'rpm'
    attribute :s3_bucket, kind_of: String
    attribute :packages, kind_of: Array, default: %w{openssl openssl-devel lua lua-devel libnghttp2-devel openldap openldap-devel pcre pcre-devel xz xz-devel}
  end
  class Provider < Chef::Provider
    include Poise
    provides :web_server
    def dependencies(pkgs)
      pkgs.each do |pkg|
        package pkg
      end
    end
    def valid_web_servers
      [
        {
          :name => 'nginx', :version => '9'
        },
        {
          :name => 'apache2', :version => '2.4.20'
        },
      ]
    end
    def verify_web_server(machine)
      valid_web_servers.each do |server|
        if machine[:name].include?(server[:name])
          if machine[:version].include?(server[:version])
            return true
          end
        end
      end
      return false
    end
    def apache_strategy
      Apache.buildit
      [
        {
          :dest => "#{Chef::Config[:file_cache_path]}/httpd.tar.gz",
          :source => "httpd-#{new_resource.httpd_version}.tar.gz",
          :untar_name => "httpd-#{new_resource.httpd_version}",
        },
        {
          :dest => "#{Chef::Config[:file_cache_path]}/apr.tar.gz",
          :source => "apr-#{new_resource.apr_version}.tar.gz",
          :untar_name => "apr-#{new_resource.apr_version}",
        },
        {
          :dest => "#{Chef::Config[:file_cache_path]}/apr-util.tar.gz",
          :source => "apr-util-#{new_resource.apr_util_version}.tar.gz",
          :untar_name => "apr-util-#{new_resource.apr_util_version}",
        },
        {
          :dest => "#{Chef::Config[:file_cache_path]}/apr-iconv.tar.gz",
          :source => "apr-iconv-#{new_resource.apr_iconv_version}.tar.gz",
          :untar_name => "apr-iconv-#{new_resource.apr_iconv_version}",
        },
      ].each do |f|
        cookbook_file f[:dest] do
          source f[:source]
          cookbook new_resource.local_cookbook
        end
        bash "untar" do
          cwd Chef::Config[:file_cache_path]
          code <<-EOH
          tar xzf #{f[:dest]}
          EOH
          not_if do ::File.exists?("#{Chef::Config[:file_cache_path]}/#{f[:untar_name]}") end
        end
      end
      if new_resource.install_deps
        dependencies(new_resource.packages)
      end
      bash "prepare apache libraries" do
        cwd Chef::Config[:file_cache_path]
        code <<-EOH
        mv apr-#{new_resource.apr_version} httpd-#{new_resource.httpd_version}/srclib/apr
        mv apr-util-#{new_resource.apr_util_version} httpd-#{new_resource.httpd_version}/srclib/apr-util
        mv apr-iconv-#{new_resource.apr_iconv_version} httpd-#{new_resource.httpd_version}/srclib/apr-iconv
        touch whatever
        EOH
        # Don't do it if you've already moved the files
        not_if do ::File.exists?("whatever") end
      end
      template "#{Chef::Config[:file_cache_path]}/httpd-#{new_resource.httpd_version}/build.sh" do
        source new_resource.apache_build_template
        cookbook new_resource.local_cookbook
        variables :context => {:options => {
          :opts => new_resource.configure,
          :list_opts => new_resource.configure_list,
        }}
        sensitive true
      end
      # build Apache
      bash "httpd" do
        cwd "#{Chef::Config[:file_cache_path]}/httpd-#{new_resource.httpd_version}"
        code <<-EOH
        bash build.sh
        make
        make install
        EOH
        not_if do ::File.exists?(new_resource.prefix) end
      end
      bash "cleanup_before_packaging" do
        cwd "/usr/local/apache2/"
        code <<-EOH
        rm -rf conf/*
        rm -rf build
        rm -rf cgi-bin
        rm -rf icons
        rm -rf man
        rm -rf manual
        EOH
      end
      if new_resource.package
        fpm new_resource.name do
          sources new_resource.package_dir
          output_type new_resource.package_format
        end
      end
      if new_resource.s3_upload
        s3 'send it to the cloud' do
          action :upload
          path "#{Chef::Config[:file_cache_path]}/#{new_resource.name}.#{new_resource.package_format}"
          key "#{new_resource.name}.#{new_resource.package_format}"
          bucket new_resource.s3_bucket
        end
      end
      return "#{Chef::Config[:file_cache_path]}/#{new_resource.name}#{new_resource.package_format}"
    end
    def nginx_strategy
      # how to install nginx goes here
      nil
    end
    def action_build
      if new_resource.resource_deps
        #include_recipe new_resource.build_essential
        nil
      end
      unless verify_web_server({:name => new_resource.name, :version => new_resource.httpd_version})
        raise Exception.new("#{new_resource.name}::#{new_resource.httpd_version} is not a valid combination, try #{self.valid_web_servers}")
      else
        case new_resource.name
        when valid_web_servers[0][:name]
          nginx_strategy
        when valid_web_servers[1][:name]
          pkg = apache_strategy
        end
      end
      return pkg
    end
  end
end
