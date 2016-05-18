include_recipe 'build-essential'

poise_service_user 'apache'
path = web_server 'apache2' do
  action :build
end
