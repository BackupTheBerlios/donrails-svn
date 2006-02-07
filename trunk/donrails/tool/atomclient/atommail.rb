#!/usr/bin/env ruby

# Author: ARAKI Yasuhiro <yasu@debian.or.jp>
# Copyright: (c) 2006 ARAKI Yasuhiro
# Licence: GPL2

require 'yaml'
require 'getoptlong'
require 'atomcheck'
require 'rmail/parser'
require 'nkf'
require 'net/smtp'

=begin

for test

$ cat ~/Mail/inbox/1115 |ruby atommail.rb  -c ~/.donrails/atompost-test.yaml -n

invoke from .forward

"|/usr/local/bin/atommail.rb -c ~/.donrails/atompost.yaml"

=end

def usage
  print "#{$0}\n\n"
  print "--config or -c=configfile:\n\t Set YAML format config file.\n"
  print "--nocheck\n\t NO CHECK article is already has posted or not. (Default checkd.)\n"
  print "--help\n\t Show this message\n"
  exit
end

# send report to report_mailaddress
def reportmail(report_mailaddress, from_mailaddress, title, reason='Sucess')
  if title
    title = NKF.nkf("-j", title) 
  else
    title = "(no title)"
  end
  msgstr = <<END_OF_MESSAGE
From: reporter
To: #{report_mailaddress}
Subject: receive atompost request
MIME-Version: 1.0
Content-Type: text/plain; charset="ISO-2022-JP"

#{reason}: accept as follows,

Title: #{title}

END_OF_MESSAGE

  Net::SMTP.start('localhost', 25) do |smtp|
    smtp.send_message msgstr, from_mailaddress, report_mailaddress
  end
end

user = nil
pass = nil
mailpass = nil
certify_mailaddress = nil
report_mailaddress = nil
target_url = nil
title = nil
body = nil
configfile = nil
format = nil
check = true
preescape = false
content_mode = nil
category = nil

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
#  mailpass = conf['mailpass'] unless mailpass
  certify_mailaddress = conf['certify_mailaddress'] unless certify_mailaddress
  report_mailaddress = conf['report_mailaddress'] unless report_mailaddress
  target_url = conf['target_url'] unless target_url
  category = conf['category'] unless category
rescue
  p $!
end

message = RMail::Parser.read(STDIN)
body = ''
bodyhtml = ''

from_mailaddress = message.header.from[0].local + '@' + message.header.from[0].domain
if certify_mailaddress
  unless certify_mailaddress.include?(from_mailaddress) 
    print from_mailaddress + " is not certified address\n"
    reportmail(report_mailaddress, from_mailaddress, title, 'Not certified address.') if report_mailaddress
    exit
  end
end

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
ap = AtomPost.new
p target_url

if bodyhtml.length > 0
  ap.atompost(target_url, user, pass, 
              title, bodyhtml, nil, 
              category, nil, check, 
              preescape, nil)

else
  ap.atompost(target_url, user, pass, 
              title, body.chomp, nil, 
              category, nil, check, 
              preescape, 'plain')
end

reportmail(report_mailaddress, from_mailaddress, title) if report_mailaddress
