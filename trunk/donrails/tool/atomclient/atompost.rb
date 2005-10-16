#!/usr/bin/env ruby

require 'net/http'
require 'wsse'
require 'getoptlong'

user = nil
pass = nil
target_url = nil
title = nil
body = nil

parser = GetoptLong.new
parser.set_options(['--username', '-a', GetoptLong::REQUIRED_ARGUMENT],
                   ['--password', '-d', GetoptLong::REQUIRED_ARGUMENT],
                   ['--target_url', GetoptLong::REQUIRED_ARGUMENT],
                   ['--title', '-h', GetoptLong::REQUIRED_ARGUMENT],
                   ['--body', '-u', GetoptLong::REQUIRED_ARGUMENT]
                   )
parser.each_option do |name, arg|
  case name
  when "--username"
    user = art.to_s
  when "--password"
    pass = art.to_s
  when "--target_url"
    target_url = art.to_s
  when "--title"
    title = art.to_s
  when "--body"
    body = art.to_s
  end
end

##
wsse = WSSE.new.generate(user, pass)
##

postbody = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<entry xmlns=\"http://purl.org/atom/ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n<title>#{title}</title>\n<content>#{body}</content>\n</entry>\n"

url = URI.parse(target_url)
req = Net::HTTP::Post.new(url.path)
req.body = postbody
req['X-WSSE'] = wsse
req['host'] = url.host
req['Content-Type']= 'application/atom+xml'
res = Net::HTTP.new(url.host, url.port).start {|http|
  ##  http.request(req, { "X-WSSE" => wsse}) # x-wsse in body.
  http.request(req)
}
p res
