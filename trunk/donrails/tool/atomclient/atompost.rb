#!/usr/bin/env ruby

require 'yaml'
require 'net/http'
require 'wsse'
require 'getoptlong'
$KCODE = "UTF8"
require 'kconv'
require 'getoptlong'
require 'cgi'


def body_to_html2(body)
  retval = ""

  pre_tag = false
  body.to_s.split(/\r\n|\r|\n/).each do |line|
    if line =~ (/\APRE/) then
      retval << '<pre>'
      pre_tag = true
      next
    elsif line =~ (/\A\/PRE/) then
      retval << '</pre>'
      pre_tag = false
      next
    end

    if pre_tag then
      retval << CGI.escapeHTML(line + "\n")
    elsif line =~ /\A\/?[A-Z~]+/        # hnf command begin CAPITAL letters.
      if line =~ (/\AOK/) then
        next
      elsif line =~ (/\A(TENKI|WEATHER|BASHO|LOCATION|TAIJU|WEIGHT|TAION|TEMPERATURE|SUIMIN|SLEEP|BGM|HOSU|STEP|HON|BOOK|KITAKU|HOMECOMING|WALK|RUN)\s+(.+)/) then
        next
      elsif line =~ (/\ASUB\s+(.+)/) then
        retval << sprintf("<p><b>%s</b>:", $1)
        next
      elsif line =~ (/\ALSUB\s+(http|https|mailto|ftp):\/\/(\S+)\s+(.+)/i) then
        retval << sprintf("<p><b><a href=\"%s://%s\">%s</a></b>", $1, $2, $3)
        next
      elsif line =~ (/\ALINK\s+(http|https|mailto|ftp):\/\/(\S+)\s+(.+)/i) then
        retval << sprintf("<a href=\"%s://%s\">%s</a>", $1, $2, $3)
        next
      elsif line =~ (/\AL?IMG\s+(l|r|n)\s+(\S+)\.(jpg|jpeg|gif|png)/i) then
        line = $2
        if $1 == 'l' then
          retval << sprintf("<img align=\"left\" src=\"%s.%s\" />", $2, $3)
        elsif $1 == 'r' then
          retval << sprintf("<img align=\"right\" src=\"%s.%s\" />", $2, $3)
        else
          retval << sprintf("<img src=\"%s.%s\" />", $2, $3)
        end
      end
      if line =~ (/\A~/) then
        retval << '<br />'
        next
      elsif line =~ (/\A(\/)?(UL|P|OL|DL)/) then
        retval << sprintf("<%s%s>", $1, $2)
        next
      elsif line =~ (/\A(\/)?(CITE)/) then
        unless $1 then
          retval << sprintf("<p><%s>", $2)
        else
          retval << sprintf("<%s%s></p>", $1, $2)
        end
        next
      elsif line =~ (/\ALI\s+(.+)/) then
        retval << sprintf("<li>%s", $1)
        next
      elsif line =~ (/\A\/LI/) then
        retval << '</li>'
        next
      end
    else
      retval << line
    end
  end

  return retval
end # def body_to_html

def title_to_html(title)
  retval = title.to_s
  if title.to_s =~ (/\A(http|https|mailto|ftp):\/\/(\S+)\s+(.+)/i) then
    retval = sprintf("<a href=\"%s://%s\">%s</a>", $1, $2, $3)
  end
  return retval
end
  
def atompost(target_url, user, pass, title, body, article_date, category)
  postbody = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<entry xmlns=\"http://purl.org/atom/ns#\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n"
  if title
    postbody += "<title>#{title_to_html(title)}</title>\n"
  end
  if article_date
    postbody += "<articledate>#{article_date}</articledate>\n"
  end
  if category
    postbody += "<category>#{category.join(" ")}</category>\n"
  end

  if body
    postbody += "<content>#{body_to_html2(body)}</content>\n</entry>\n"
  end

  url = URI.parse(target_url)
  req = Net::HTTP::Post.new(url.path)

#  req.body = postbody ## ruby1.9 and later

  req['X-WSSE'] = WSSE.new.generate(user, pass)
  req['host'] = url.host
  req['Content-Type']= 'application/atom+xml'
  res = Net::HTTP.new(url.host, url.port).start {|http|
    http.request(req, postbody)
#    http.request(req) ## ruby1.9 and later
  }

  p res
  case res
  when Net::HTTPCreated 
    p "Success, #{article_date}"
    return res
  when Net::HTTPRedirection
    p "Redirect to res['location']"
    atompost(res['location'], user, pass, title, body, article_date)
  else
    res.error!
  end
end

def addhnf(target_url, user, pass, f)
  if f =~ /d(\d{4})(\d{2})(\d{2})\.hnf/
    ymd = $1 + '-' + $2 + '-' + $3
    hnfdate = $1 + $2 + $3

    fftmp = open(f, "r")
    mtime = fftmp.mtime
    ftmpread = fftmp.read
    ftmp = Kconv.toutf8(ftmpread).split(/\n/)
    fftmp.close
    ftmp.shift

    y = Hash.new
    y['ymd'] = ymd
    y['mtime'] = mtime
    y['text'] = ''
    daynum = 0

    ftmp.each do |x|
      if x =~ /^(CAT|NEW|LNEW)\s+.+/
        if y['title']
#          hdb.hnfinput(y)
          atompost(target_url, user, pass, y['title'], y['text'], y['ymd'], y['cat'])
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
    atompost(target_url, user, pass, y['title'], y['text'], y['ymd'], y['cat'])
#    hdb.hnfinput(y)
  end
end


user = nil
pass = nil
target_url = nil
title = nil
body = nil

begin
  fconf = open("#{ENV['HOME']}/.donrails/atompost.yaml", "r")
  conf = YAML::load(fconf)
  user = conf['user']
  pass = conf['pass']
  target_url = conf['target_url']
rescue
  p $!
end


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
    user = arg.to_s
  when "--password"
    pass = arg.to_s
  when "--target_url"
    target_url = arg.to_s
  when "--title"
    title = arg.to_s
  when "--body"
    body = arg.to_s
  end
end

if (body and title)
  atompost(target_url, user, pass, title, body, nil)
end

ARGV.each do |f|
  if f =~ /d\d{8}.hnf/
    # HNF 
    addhnf(target_url, user, pass, f)
  else
    p "unsupported filetype: #{f}"
  end
end
