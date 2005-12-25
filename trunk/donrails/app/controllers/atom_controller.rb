require 'rexml/document'
require 'cgi'

# rfc4287

class AtomController < ApplicationController
  layout "atom", :only => [
    :preview
  ]
  before_filter :wsse_auth, :except => :feed

  def wsse_auth
    if request.env["HTTP_X_WSSE"]
      if false == wsse_match(request.env["HTTP_X_WSSE"])
        render :text => "you are not valid user for atom.", :status => 403
      end
    elsif request.env["REMOTE_ADDR"] == "127.0.0.1"
      # for debug
    else
      render :text => "you are not valid user for atom. Use with WSSE.", :status => 403
    end
  end

  # atom endpoint 
  def index
    @latest_article = Article.find(:first, :order => 'id DESC')
    @recent_articles = Article.find(:all, :order => 'id DESC', :limit => 20)
  end

  # atom feed
  def feed
    if @params['id'] == nil
      @articles = Article.find(:all, :order => 'id DESC', :limit => 20)
    else
      begin
        @article = Article.find(@params['id'])
      rescue
        render :text => "no this id", :status => 400
      end
    end
  end

  # atom post
  def post
    if request.method == :post
      begin
        if @params['id']
          aris1 = Article.new("id" => @params['id'])
        else
          aris1 = Article.new
        end
        atom_update_article2(aris1, request.raw_post)
        aris1.save
        @article = aris1
        render :status => 201 # 201 Created @ Location
      rescue
        p $!
        render :status => 404
      end
    end
  end

  # atom edit
  def edit
    if request.method == :put
      begin
        aris1 = Article.find(@params['id'])
        atom_update_article2(aris1, request.raw_post)
        aris1.save
        @article = aris1
        render :action => "post", :status => 200
      rescue
        p $!
        render :status => 404
      end
    elsif request.method == :delete
      begin
        Article.destroy(@params['id'])
        render :text => "dslete #{@params['id']}", :status => 204
      rescue
        render :text => "no method #{request.method}", :status => 403
      end
    else
      render :status => 404
    end
  end

  def categories
    if @params['id'] == nil
      render :text => "no method #{request.method}", :status => 400
    end

    if @params['id']
      begin
        @article = Article.find(@params['id'])
      rescue
        render :text => "no this id", :status => 400
      end
    end
  end

  private

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

    # atomContent?
    if xml.root.elements['content'].attributes["mode"] == "escaped"
      databody = '<content>' + CGI.unescapeHTML(xml.root.elements['content'].text) + '</content>'
    else
      databody = xml.root.elements['content'].to_s
    end
    article.body = parsecontent(databody)
    article.format = "html"
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
    if xml.root.elements['articledate'].text
      article.article_date = xml.root.elements['articledate'].text
    else
      article.article_date = Time.now
    end

    blogping = Blogping.find_all
    sendping(article, blogping)
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

end
