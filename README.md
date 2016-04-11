# web-cookbook

This is a web cookbook made in order to translate descriptive behaviors into their web implementations.  This means recognizing that
while there is an array of overlapped and sometimes not overlapped functionality between web servers, in the world of automation it
seems we still describe what the implementation is doing rather than what the implementation should do.

A great example is building the web server

```
web_server 'apache2' do
  action :build
end
```
