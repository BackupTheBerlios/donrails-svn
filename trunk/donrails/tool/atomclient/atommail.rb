#!/usr/bin/env ruby

# Author: ARAKI Yasuhiro <yasu@debian.or.jp>
# Copyright: (c) 2006 ARAKI Yasuhiro
# Licence: GPL2

require 'yaml'
require 'getoptlong'
require 'atomcheck'
require 'rmail/parser'
require 'nkf'

=begin

for test

$ cat ~/Mail/inbox/1115 |ruby atommail.rb  -c ~/.donrails/atompost-test.yaml -n

invoke from .forward

"|/usr/local/bin/atommail.rb -c ~/.donrails/atompost.yaml"

=end

def usage
  print "#{$0}\n\n"
#  print "--username or -a=username:\n\t Set username for WSSE auth.\n"
#  print "--password or -p=password:\n\t Set password for WSSE auth.\n"
#  print "--target_url=target_url:\n\t Set URL for Atom POST.\n"
#  print "--title or -t=title:\n\t Set TITLE for your post article.\n"
  print "--config or -c=configfile:\n\t Set YAML format config file.\n"
#  print "--html\n\t Set article format to HTML.\n" 
#  print "--hnf\n\t Set article format to HNF.\n"
  print "--nocheck\n\t NO CHECK article is already has posted or not. (Default checkd.)\n"
#  print "--preescape\n\t html escape in <pre></pre> text. (Default no preescaped.)\n\t(Some text caused internal server error without this option.)\n"
#  print "--content-mode=(escaped)\n\t <content></content> encode mode. (Default no encoded.)\n\t\t'escaped' is the only supported encode mode."
  print "--help\n\t Show this message\n"
  exit
end

user = nil
pass = nil
target_url = nil
title = nil
body = nil
configfile = nil
format = nil
check = true
preescape = false
content_mode = nil

parser = GetoptLong.new
parser.set_options(['--config', '-c', GetoptLong::REQUIRED_ARGUMENT],
                   ['--nocheck', '--nc', '-n', GetoptLong::NO_ARGUMENT],
                   ['--help', '--usage', '-h', GetoptLong::NO_ARGUMENT]
                   )
parser.each_option do |name, arg|
  case name
  when "--config"
    configfile = arg.to_s
  when "--nocheck"
    check = false
  when "--help"
    usage
  else
    usage
  end
end


begin
  if configfile
    fconf = open(configfile, "r")
  else
    fconf = open("#{ENV['HOME']}/.donrails/atompost.yaml", "r")
  end
  conf = YAML::load(fconf)
  user = conf['user'] unless user
  pass = conf['pass'] unless pass
  target_url = conf['target_url'] unless target_url
rescue
  p $!
end


message = RMail::Parser.read(STDIN)
body = ''
bodyhtml = ''

#p message.header.content_type
title = NKF.nkf("-m -w", message.header.subject)

## multipart message is not stable...
if message.multipart? and message.header.content_type == "multipart/alternative"
  message.each_part do |mp|
    if mp.header.content_type == "text/html"
      bodyhtml = NKF.nkf("-w", mp.body)
    end
    if mp.header.content_type == "text/plain"
      body = NKF.nkf("-w", mp.body)
    end
  end
elsif message.multipart?
  message.each_part do |mp|
    if mp.header.content_type =~ /text\//
      bodyhtml = NKF.nkf("-w", mp.body)
      break
    end
  end
else
  body = NKF.nkf("-w", message.body)
end

puts NKF.nkf('-e', title)
#puts NKF.nkf('-e', body)
puts NKF.nkf('-e', bodyhtml)
p body.length
p bodyhtml.length

ap = AtomPost.new
p target_url
#ap.atompost(target_url, user, pass, 
#            title, body, nil, 
#            nil, nil, check, preescape, content_mode)

if bodyhtml.length > 0
  ap.atompost(target_url, user, pass, 
              title, bodyhtml, nil, 
              nil, nil, check, 
              preescape, nil)

else
  ap.atompost(target_url, user, pass, title, body, nil, nil, nil, check, preescape, 'plain')
end
