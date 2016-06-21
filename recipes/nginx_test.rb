package 'bzip2'
web_server "nginx" do
  action :build
  httpd_version '1.10'
  use_company true
  company node[:web][:company]
end
