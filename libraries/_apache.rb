# CURRENTLY APACHE WORK IS ACTUALLY DONE IN THE WEBSERVER LIB
require 'poise'
require 'chef/resource'
require 'chef/provider'

module ApacheServer
  class  Resource < Chef::Resource
    include Poise
    provides :apache_server
    actions :build
    attribute :name, name_attribute: true
    attribute :version, default: '1.11.1'
    attribute :user, default: 'root'
    attribute :group, default: 'root'
    attribute :mode, default: '0777'
    attribute :method, default: :git
    attribute :install_deps, default: true
    attribute :deps, default: %w{git hg golang pcre pcre-devel zlib zlib-devel openssl openssl-devel}
    attribute :git_branch, default: 'master'
    attribute :git_repository, default: 'https://github.com/Berimboss/httpd.git'
    attribute :git_source_path, default: "#{::File.join(Chef::Config[:file_cache_path], 'httpd')}"
    attribute :go_get_builder, default: 'github.com/Berimboss/apache-build'
    attribute :go_path, default: "#{::File.join(Chef::Config[:file_cache_path], 'go')}"
    attribute :nginx_build_directory, default: "#{::File.join(Chef::Config[:file_cache_path], 'httpd', 'build')}"
    attribute :prefix_path, default: "#{::File.join(Chef::Config[:file_cache_path], 'httpd', 'pkg')}"
    attribute :arch, default: 'x86_64'
    attribute :pkg_extension, default: 'rpm'
    attribute :local_cookbook, default: 'poise-web'
  end
  class  Provider < Chef::Provider
    include Poise
    provides :apache_server
    def build_runit_services(context)
      directory context[:runit_directory] do
        recursive true
      end
    end
    def prefix_path
      "#{new_resource.prefix_path}"
    end
    def sbin_dir
      "#{::File.join(self.prefix_path, 'sbin')}"
    end
    def conf_dir
      "#{::File.join(self.prefix_path, 'conf')}"
    end
    def sbin_path
      "#{::File.join(self.prefix_path, 'sbin', 'nginx')}"
    end
    def conf_path
      "#{::File.join(self.prefix_path, 'conf')}/nginx.conf"
    end
    def pid_path
      "#{::File.join(self.prefix_path, 'logs')}/nginx.pid"
    end
    def error_log_path
      "#{::File.join(self.prefix_path, 'logs')}/error.log"
    end
    def http_log_path
      "#{::File.join(self.prefix_path, 'logs')}/access.log"
    end
    def options
      [
        {:symbol => '--prefix', :value => self.prefix_path},
        {:symbol => '--sbin-path', :value => self.sbin_path},
        {:symbol => '--conf-path', :value => self.conf_path},
        {:symbol => '--pid-path', :value => self.pid_path},
        {:symbol => '--error-log-path', :value => self.error_log_path},
        {:symbol => '--http-log-path', :value => self.http_log_path},
        {:symbol => '--user', :value => new_resource.user},
        {:symbol => '--group', :value => new_resource.group}
      ]
    end
    def final_match_name
      "#{new_resource.name}-#{new_resource.version}-#{new_resource.arch}.#{new_resource.pkg_extension}"
    end
    def common
      [
       new_resource.git_source_path,
       new_resource.nginx_build_directory,
       new_resource.go_path,
       self.prefix_path,
       self.sbin_dir,
      ].each do |dir|
        directory dir do
          recursive true
          user new_resource.user
          group new_resource.group
        end
      end
      if new_resource.install_deps
        new_resource.deps.each do |pkg|
          package pkg
        end
      end
      yield
    end
    def action_build
      case new_resource.method
      when :git
        common do
          git new_resource.git_source_path do
            revision new_resource.git_branch
            repository new_resource.git_repository
            group new_resource.group
            user new_resource.user
          end
          opts = "./configure \\\n"
          self.options.each do |opt|
            opts << "#{opt[:symbol]}=#{opt[:value]} \\\n"
          end
          file "#{Chef::Config[:file_cache_path]}/build.configure" do
            content opts
          end
          ruby_block "build #{new_resource.name}" do
            block do
              Dir.chdir new_resource.git_source_path
              ENV['GOPATH'] = new_resource.go_path
              system "go get -u #{new_resource.go_get_builder}"
              system <<-EOH
              #{::File.join(new_resource.go_path, 'bin')}/nginx-build -v #{new_resource.version} -d #{new_resource.nginx_build_directory} -c #{Chef::Config[:file_cache_path]}/build.configure && cd #{::File.join(new_resource.nginx_build_directory, 'nginx', new_resource.version, "nginx-#{new_resource.version}")} && make install
              EOH
            end
          end
          self.default_templates.each do |tmp|
            template tmp[:path] do
              source tmp[:src]
              user new_resource.user
              group new_resource.group
              mode new_resource.mode
              sensitive true
              cookbook new_resource.local_cookbook
            end
          end
          fpm new_resource.name do
            sources [new_resource.prefix_path, new_resource.nginx_build_directory]
          end
          bash "detection test" do
            code <<-EOH
            touch #{::File.join(Chef::Config[:file_cache_path], 'detection_test')}
            EOH
            not_if do ::File.exists?("#{::File.join(Chef::Config[:file_cache_path], self.final_match_name)}") end
          end
        end
      end
    end
  end
end
