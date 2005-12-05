# The methods added to this helper will be available to all templates in the application.

require 'delegator'
require 'donplugin'
require 'time'
require 'jcode'

require 'rexml/document'

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

  def atom_input_parse(raw_post)
    xml = REXML::Document.new(raw_post)
    data = {}

    if xml.root.elements['title'].text
      data['title'] = xml.root.elements['title'].text
    elsif xml.root.elements['title'].to_s
      if xml.root.elements['title'].to_s =~ (/^<title>(.+)<\/title>$/)
        data['title'] = $1
      end
    else
      data['title'] = ''
    end

    if xml.root.elements['articledate'].text
      data['article_date'] = xml.root.elements['articledate'].text
    else
      data['article_date'] = Time.now
    end

    if xml.root.elements['content'].attributes["mode"] == "escaped"
      data['body'] = xml.root.elements['content'].text
      data['body'].gsub(/&amp;/, "&")
      data['body'].gsub(/&quot;/, "\"")
      data['body'].gsub(/&lt;/, "<")
      data['body'].gsub(/&gt;/, ">")
    else
      data['body'] = xml.root.elements['content'].to_s
    end

    return xml, data
  end

  def atom_update_article(article, data, xml)
    article.title = data['title']
    article.body = data['body']
    article.format = "plain"
    article.size = article.body.size
    if data['article_date']
      article.article_date = data['article_date']
    else
      article.article_date = Time.now
    end
    article.article_mtime = Time.now
    if xml.root.elements['category'].text
      bind_article_category(article, xml.root.elements['category'].text)
    end
    blogping = Blogping.find_all
    sendping(article, blogping)
  end

  def bind_article_category(article, category)
    cat1 = category.split(' ')
    cat1.each do |cat|
      aris3 = Category.find(:first, :conditions => ["name = ?", cat])
      if aris3
        article.categories.push_with_attributes(aris3)
      else
        aris2 = Category.new("name" => cat)
        aris2.save
        article.categories.push_with_attributes(aris2)
      end
    end
  end

end

