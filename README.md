# web-cookbook

Centos6 and Centos7 mainly supported


- Builds apache2
```
web_server 'apache2' do
  action :build
end
```

- Builds nginx 1.10
```
web_server 'nginx' do
  action :build
  httpd_version '1.10'
end
```

The web_server interfaces purpose is to abstract managing popular web servers creation and packaging.
one of the purposes is to be able to quickly repackage while being able to pass run time parameters to building the servers.
since the lwrp will abstract the creation all the way to outputting an rpm, specific versions are supported and x86_64 largely assumed.

Current support matrix is

* nginx - someversion
* apache2 - someversion
