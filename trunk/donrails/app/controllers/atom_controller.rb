require 'rexml/document'

class AtomController < ApplicationController
  layout "atom", :only => [
    :preview
  ]
  before_filter :wsse_auth

  def wsse_auth
    if request.env["HTTP_X_WSSE"]
      if false == wsse_match("araki", "tone", request.env["HTTP_X_WSSE"])
        render :text => "you are not valid user for atom", :status => 401
      end
    elsif request.env["REMOTE_ADDR"] == "192.168.216.122"
      # for debug
    else
      render :text => "you are not valid user for atom", :status => 401
    end
  end

  # atom endpoint 
  def index
    @latest_article = Article.find(:first, :order => 'id DESC')
  end

  # atom post
  def post
    logger.info(request.method)
    if request.method == :post

      xml = REXML::Document.new(request.raw_post)
      data = {}
      data['title'] = xml.root.elements['title'].text

      if xml.root.elements['content'].attributes["mode"] == "escaped"
        data['body'] = xml.root.elements['content'].text
        data['body'].gsub(/&amp;/, "&")
        data['body'].gsub(/&quot;/, "\"")
        data['body'].gsub(/&lt;/, "<")
        data['body'].gsub(/&gt;/, ">")
      else
        data['body'] = xml.root.elements['content'].text
      end

      if @params['id']
        aris1 = Article.new
        aris1.id = @params['id']
        aris1.title = data['title']
        aris1.body = data['body']
        aris1.format = "plain"
        aris1.size = aris1.body.size
        aris1.article_date = Time.now
        aris1.article_mtime = Time.now
        aris1.save
        @article = aris1
        render :status => 201
      end
    end
  end

  # atom edit
  def edit
    logger.info(request.method)
    if request.method == :put

      xml = REXML::Document.new(request.raw_post)
      data = {}
      data['title'] = xml.root.elements['title'].text

      if xml.root.elements['content'].attributes["mode"] == "escaped"
        data['body'] = xml.root.elements['content'].text
        data['body'].gsub(/&amp;/, "&")
        data['body'].gsub(/&quot;/, "\"")
        data['body'].gsub(/&lt;/, "<")
        data['body'].gsub(/&gt;/, ">")
      else
        data['body'] = xml.root.elements['content'].text
      end

      aris1 = Article.find(@params['id'])
      aris1.title = data['title']
      aris1.body = data['body']
      aris1.format = "plain"
      aris1.size = aris1.body.size
      aris1.article_date = Time.now
      aris1.article_mtime = Time.now
      aris1.save
      @article = aris1
      render :action => "post", :status => 200
    elsif request.method == :delete
      Article.destroy(@params['id'])
      render :text => "dslete #{@params['id']}", :status => 200
    else
      render :text => "no method #{request.method}", :status => 403
    end
  end
end