include_recipe 'build-essential'

s3 = true
no_package = false
web_server 'apache2' do
  action :build
  if s3
    s3_upload true
    s3_bucket 'anaplan-devops'
  end
  if no_package
    package false
  end
end
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
end
configuration 'test configuration again'
mod 'mod_ssl' do
  path '/usr/local/apache2/modules/mod_ssl.so'
end
