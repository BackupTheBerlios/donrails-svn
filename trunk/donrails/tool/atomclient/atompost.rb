#!/usr/bin/env ruby

require 'yaml'
require 'net/http'
require 'wsse'
require 'getoptlong'
$KCODE = "UTF8"
require 'kconv'
require 'getoptlong'
require 'hnfhelper'

require 'rexml/document'
require 'htree'
require 'time'

require 'atomcheck'

def atompost(target_url, user, pass, 
             title, body, article_date, 
             category, format, check=true)
  if check
    as = AtomStatus.new
    id = as.check(target_url, title, body)
    if id == 0
      print "Already posted\n"
      return false
    end
  end
  postbody = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<entry xmlns=\"http://purl.org/atom/ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n"
  postbody += "<articledate>#{article_date}</articledate>\n" if article_date
  postbody += "<category>#{category.join(" ")}</category>\n" if category
  if format == 'hnf'
    title = HNFHelper.new.title_to_html(title) if title
    body = HNFHelper.new.body_to_html2(body) if body
  end
  postbody += "<title>#{title}</title>\n" if title
  postbody += "<content>#{body}</content>\n" if body
  postbody += "</entry>\n"

  xml = HTree.parse(postbody).to_rexml
  postbody = xml.root.to_s

  url = URI.parse(target_url)
  req = Net::HTTP::Post.new(url.path)

  req['X-WSSE'] = WSSE.new.generate(user, pass)
  req['host'] = url.host
  req['Content-Type']= 'application/atom+xml'
  res = Net::HTTP.new(url.host, url.port).start {|http|
    http.request(req, postbody)
  }

#  p res
  case res
  when Net::HTTPCreated 
    p "Success, #{article_date}"
    as.update(id, 201)
    return res
  when Net::HTTPRedirection
    p "Redirect to res['location']"
    atompost(res['location'], user, pass, title, body, article_date, category, format, check)
  else
    p "Error, #{article_date}"
    p res
    res.error!
    as.update(id, -1)
  end
end

def addhtml(target_url, user, pass, f)
  fftmp = open(f, "r")
  mtime = fftmp.mtime
  ftmpread = fftmp.read
  ftmp = Kconv.toutf8(ftmpread)
  title = ''
  body = ''

  xml = HTree.parse(ftmp).to_rexml
  title = xml.root.elements['head/title'].to_s 
  body = xml.root.elements['body'].to_s
  article_date = mtime.iso8601

  atompost(target_url, user, pass, title, body, article_date, nil, 'html', check)
end

def addhnf(target_url, user, pass, f, check=true)
  if f =~ /d(\d{4})(\d{2})(\d{2})\.hnf/
    ymd = $1 + '-' + $2 + '-' + $3
  end
  hnfdate = $1 + $2 + $3

  fftmp = open(f, "r")
  mtime = fftmp.mtime
  ftmpread = fftmp.read
  ftmp = Kconv.toutf8(ftmpread).split(/\n/)
  fftmp.close
  ftmp.shift

  y = Hash.new
  if ymd
    y['ymd'] = ymd
  else
    y['ymd'] = mtime
  end
  y['mtime'] = mtime
  y['text'] = ''
  daynum = 0

  ftmp.each do |x|
    if x =~ /^(CAT|NEW|LNEW)\s+.+/
      if y['title']
        atompost(target_url, user, pass, y['title'], y['text'], y['ymd'], y['cat'], 'hnf', check)
        y.clear
        y['ymd'] = ymd
        y['mtime'] = mtime
        y['text'] = ''
      end
    end

    if x =~ /^CAT\s+(.+)/
      y['cat'] = $1.split(/\W+/)
      next
    end

    if x =~ /^(NEW|LNEW)\s+(.+)/
      y['title'] = $2
      daynum += 1
      y['hnfid'] = "#{hnfdate}#{daynum}"
      next
    end

    y['text'] += x + "\n"

  end
  atompost(target_url, user, pass, y['title'], y['text'], y['ymd'], y['cat'], 'hnf')
end


user = nil
pass = nil
target_url = nil
title = nil
body = nil
configfile = nil
format = nil
check = true

parser = GetoptLong.new
parser.set_options(['--username', '-a', GetoptLong::REQUIRED_ARGUMENT],
                   ['--password', '-d', GetoptLong::REQUIRED_ARGUMENT],
                   ['--target_url', GetoptLong::REQUIRED_ARGUMENT],
                   ['--title', '-h', GetoptLong::REQUIRED_ARGUMENT],
                   ['--config', '-c', GetoptLong::REQUIRED_ARGUMENT],
                   ['--html', GetoptLong::NO_ARGUMENT],
                   ['--hnf', GetoptLong::NO_ARGUMENT],
                   ['--body', '-u', GetoptLong::REQUIRED_ARGUMENT],
                   ['--nocheck', '-n', GetoptLong::NO_ARGUMENT]
                   )
parser.each_option do |name, arg|
  case name
  when "--username"
    user = arg.to_s
  when "--password"
    pass = arg.to_s
  when "--target_url"
    target_url = arg.to_s
  when "--title"
    title = arg.to_s
  when "--body"
    body = arg.to_s
  when "--config"
    configfile = arg.to_s
  when "--html"
    format = 'html'
  when "--hnf"
    format = 'hnf'
  when "--nocheck"
    check = false
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

if (body and title)
  atompost(target_url, user, pass, 
           title, body, nil, 
           nil, nil, check)
end

ARGV.each do |f|
  if (format == 'hnf' or (f =~ /d\d{8}.hnf/))
    addhnf(target_url, user, pass, f, check)
  elsif (format == 'html' or (f =~ /.html?/i))
    addhtml(target_url, user, pass, f, check)
  else
#    p "unsupported filetype: #{f}"
#    addguess(target_url, user, pass, f)
  end
end
