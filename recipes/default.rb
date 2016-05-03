include_recipe 'build-essential'

poise_service_user 'apache'
s3 = true
no_package = false
#web_server 'apache2' do
#  action :build
#  if s3
#    s3_upload true
#    s3_bucket 'anaplan-devops'
#  end
#  if no_package
#    package false
#  end
#end
directory '/server' do
  recursive true
end
s3 "download apache2" do
  action :download
  bucket 'anaplan-devops'
  key 'apache2.rpm'
  path '/server/apache2.rpm'
end
package '/server/apache2.rpm' do
  action :remove
end
package '/server/apache2.rpm'
configuration 'test configuration'
configuration 'purge it' do
  action :purge
  user 'apache'
  group 'apache'
end
configuration 'test configuration again' do
  user 'apache'
  group 'apache'
end
mod 'dir_module' do
  path '/usr/local/apache2/modules/mod_dir.so'
  user 'apache'
  group 'apache'
end
mod 'ssl_module' do
  path '/usr/local/apache2/modules/mod_ssl.so'
  user 'apache'
  group 'apache'
end
mod 'unixd_module' do
  path '/usr/local/apache2/modules/mod_unixd.so'
  user 'apache'
  group 'apache'
end
mod 'authz_core_module' do
  path '/usr/local/apache2/modules/mod_authz_core.so'
  user 'apache'
  group 'apache'
end
mod 'authn_core_module' do
  path '/usr/local/apache2/modules/mod_authn_core.so'
  user 'apache'
  group 'apache'
end
static 'welcome'
directory '/www/test/' do
  recursive true
  user 'apache'
  group 'apache'
end
file '/www/test/hello.html' do
  content <<-EOH
  <html>
    <body>
      Things seem to be going well
    </body>
  </html>
  EOH
end
poise_service 'apache2' do
  provider :sysvinit
  command 'custom template so it doesnt matter'
  options :pid_file => '/usr/local/apache2/logs/httpd.pid',
    :template => 'service.altered.erb',
    :command => '/usr/local/apache2/bin/httpd',
    :apachectl_bin => '/usr/local/apache2/bin/apachectl'
end
