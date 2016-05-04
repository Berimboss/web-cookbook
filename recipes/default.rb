include_recipe 'build-essential'

poise_service_user 'apache'
web_server 'apache2' do
  action :build
  package false
  end
end
