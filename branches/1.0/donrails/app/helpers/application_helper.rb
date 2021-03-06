# The methods added to this helper will be available to all templates in the application.

require 'delegator'
require 'donplugin'
require 'time'
require 'jcode'

module ApplicationHelper

=begin rdoc

=== ApplicationHelper#don_supported_formats

=end

  def don_supported_formats
    return DonRails::DataFormatDelegator.formatlist
  end # def don_supported_formats

=begin rdoc

=== ApplicationHelper#don_get_object(obj, type)

=end

  def don_get_object(obj, type)
    return DonRails::DataFormatDelegator.new(obj, type)
  end # def don_get_object

=begin rdoc

=== ApplicationHelper#don_chomp_tags(text)

=end

  def don_chomp_tags(text)
    if text.nil? then
      return ""
    else
      return text.gsub(/<\/?\w+(?:\s+[^>]*)*>/m, '')
    end
  end # def don_chomp_tags

  def pub_date(time)
    time.iso8601
  end

=begin rdoc

=== ApplicationHelper#don_insert_stylesheet_link_tags

=end

  def don_get_stylesheets
    DonRails::Plugin.stylesheets
  end # def don_get_stylesheets

=begin rdoc

=== ApplicationHelper#don_mb_truncate(text, length = 30, truncate_string = "...")

=end

  def don_mb_truncate(text, length = 30, truncate_string = "...")
    text = text.gsub(/<\/?\w+(?:\s+[^>]*)*>/m, '')
    retval = text

    return "" if text.nil?
    mbtext = text.each_char
    if mbtext.length > length then
      retval = mbtext[0..(length - truncate_string.length)].join + truncate_string
    end

    return retval
  end # def don_mb_truncate

  def article_url(article, only_path = true)
    url_for :only_path => only_path, 
    :controller=>"notes", 
    :action =>"show_title", 
    :id => article.id
  end

  def sendping(article, blogping)
    articleurl = article_url(article, false)
    urllist = Array.new

    blogping.each do |ba|
      urllist.push(ba.server_url)
    end
    if urllist.size > 0
      article.send_pings2(articleurl, urllist)
    end
  end

end

