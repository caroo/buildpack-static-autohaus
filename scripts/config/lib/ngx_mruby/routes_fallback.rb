# ghetto require, since mruby doesn't have require
eval(File.read('/app/bin/config/lib/nginx_config_util.rb'))

USER_CONFIG = "/app/static.json"

config    = {}
config    = JSON.parse(File.read(USER_CONFIG)) if File.exist?(USER_CONFIG)
req       = Nginx::Request.new
uri       = req.var.uri
proxies   = config["proxies"] || {}
redirects = config["redirects"] || {}
brand_redirects = config["brand_redirects"] || {}
all_cities = config['all_cities'] || []
pagination_redirects = config['pagination_redirects'] || []

if proxy = NginxConfigUtil.match_proxies(proxies.keys, uri)
  "@#{proxy}"
elsif redirect = NginxConfigUtil.match_redirects(redirects.keys, uri)
  "@#{redirect}"
elsif brand_redirect = NginxConfigUtil.match_brands_redirects(brand_redirects.keys, uri)
  "@brand_#{brand_redirect}"
elsif NginxConfigUtil.match_pagination_error(pagination_redirects, uri)
  "@410"
elsif NginxConfigUtil.match_dealers_error(all_cities, uri)
  "@410"
else
  "@404"
end
