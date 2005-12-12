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

def usage
  print "#{$0}\n\n"
  print "--username or -a=username:\n\t Set username for WSSE auth.\n"
  print "--password or -p=password:\n\t Set password for WSSE auth.\n"
  print "--target_url=target_url:\n\t Set URL for Atom POST.\n"
  print "--title or -t=title:\n\t Set TITLE for your post article.\n"
  print "--config or -c=configfile:\n\t Set YAML format config file.\n"
  print "--html\n\t Set article format to HTML.\n" 
  print "--hnf\n\t Set article format to HNF.\n"
  print "--nocheck\n\t NO CHECK article is already has posted or not. (Default checkd.)\n"
  print "--help\n\t Show this message\n"
  exit
end
def atompost(target_url, user, pass, 
             title, body, article_date, 
             category, format, check=true)
  as = AtomStatus.new
  id = as.check(target_url, title, body, check)
  if check
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

  case res
  when Net::HTTPCreated 
    p "Success, #{article_date}"
    as.update(id, 201,check)
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
  atompost(target_url, user, pass, y['title'], y['text'], y['ymd'], y['cat'], 'hnf', check)
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
                   ['--password', '-p', GetoptLong::REQUIRED_ARGUMENT],
                   ['--target_url', GetoptLong::REQUIRED_ARGUMENT],
                   ['--title', '-t', GetoptLong::REQUIRED_ARGUMENT],
                   ['--config', '-c', GetoptLong::REQUIRED_ARGUMENT],
                   ['--html', GetoptLong::NO_ARGUMENT],
                   ['--hnf', GetoptLong::NO_ARGUMENT],
                   ['--body', '-b', GetoptLong::REQUIRED_ARGUMENT],
                   ['--nocheck', '-n', GetoptLong::NO_ARGUMENT],
                   ['--help', '--usage', '-h', GetoptLong::NO_ARGUMENT]
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
