web_server "nginx" do
  action :build
  httpd_version '1.10'
  company node[:web][:company]
end
