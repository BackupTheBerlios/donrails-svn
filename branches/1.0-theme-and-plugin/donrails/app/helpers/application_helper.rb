# The methods added to this helper will be available to all templates in the application.

require 'delegator'
require 'donplugin'
require 'time'
require 'jcode'

require 'rexml/document'
require 'cgi'

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

  def parsecontent(databody)
    if databody =~ (/^<content(.*)<\/content>/im)
      doc = REXML::Document.new(databody)
      elems = doc.root.elements
      elems.each("pre") do |elem|
        if elem.to_s =~ (/^<pre>(.*)<\/pre>$/m)
          elem_escape = CGI.escapeHTML(CGI.unescapeHTML($1))
        end
        e = REXML::Element.new("pre")
        e.add_text(elem_escape)
        elems[elems.index(elem)] = e
      end
      databody = doc.to_s
    end
    return databody
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

  # rfc4287 atom:entry
  #           atomAuthor*
  #           & atomCategory*
  #           & atomContent?
  #           & atomContributor*
  #           & atomId
  #           & atomLink*
  #           & atomPublished?
  #           & atomRights?
  #           & atomSource?
  #           & atomSummary?
  #           & atomTitle
  #           & atomUpdated
  #           & extensionElement
  def atom_update_article2(article, raw_post)
    xml = REXML::Document.new(raw_post)
    databody = String.new

    # atomAuthor # XXX

    # atomCategory* 
    #    atomCategory =
    #      element atom:category {
    #        atomCommonAttributes,
    #        attribute term { text },
    #        attribute scheme { atomUri }?,
    #        attribute label { text }?,
    #        undefinedContent
    #      }

    if xml.root.elements['category']
      if xml.root.elements['category'].text
        bind_article_category(article, xml.root.elements['category'].text)
      elsif xml.root.elements['category'].attributes["term"]
        cat1 = String.new
        xml.root.each_element("category") do |elem|
          cat1 += elem.attributes['term']
          cat1 += ' '
        end
        bind_article_category(article, cat1)
      end
    end

    if xml.root.elements['content'].attributes["type"] == "text/html"
      article.format = "html"
    elsif xml.root.elements['content'].attributes["type"] == "text/plain"
      article.format = "plain"
    elsif xml.root.elements['content'].attributes["type"] == "text/x-hnf"
      article.format = "hnf"
    elsif xml.root.elements['content'].attributes["type"] == "text/x-rd"
      article.format = "rd"
    elsif xml.root.elements['content'].attributes["type"] == "text/x-wiliki"
      article.format = "wiliki"
    else
      article.format = "html" # default
    end

    # atomContent?
    if xml.root.elements['content'].attributes["mode"] == "escaped"
      databody = '<content>' + CGI.unescapeHTML(xml.root.elements['content'].text) + '</content>'
    else
      databody = xml.root.elements['content'].to_s
    end
    article.body = parsecontent(databody)
    article.size = article.body.size

    # atomContributor* # XXX
    # atomLink* # XXX
    # atomPublished? # XXX
    # atomRights? # XXX
    # atomSource? # XXX atom:entry is copied from one feed into another feed
    # atomSummary? # XXX

    #  atomTitle
    if xml.root.elements['title'].text
      article.title = xml.root.elements['title'].text
    elsif xml.root.elements['title'].to_s
      if xml.root.elements['title'].to_s =~ (/^<title>(.+)<\/title>$/)
        article.title = $1
      end
    end

    # atomUpdated
    if xml.root.elements['updated'] and xml.root.elements['updated'].text
      article.article_mtime = xml.root.elements['updated'].text
    else
      article.article_mtime = Time.now
    end

    # extensionElement
    if xml.root.elements['articledate'] and xml.root.elements['articledate'].text
      article.article_date = xml.root.elements['articledate'].text
    else
      article.article_date = Time.now
    end

    blogping = Blogping.find(:all, :conditions => ["active = 1"])
    if blogping and blogping.size > 0
      sendping(article, blogping)
    end
  end

end

