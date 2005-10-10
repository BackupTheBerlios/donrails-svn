require 'rexml/document'

class AtomController < ApplicationController
  layout "atom", :only => [
    :preview
  ]
  before_filter :wsse_auth, :except => :feed

  def wsse_auth
    if request.env["HTTP_X_WSSE"]
      if false == wsse_match(request.env["HTTP_X_WSSE"])
        render :text => "you are not valid user for atom", :status => 403
      end
    elsif request.env["REMOTE_ADDR"] == "127.0.0.1"
      # for debug
    else
      render :text => "you are not valid user for atom", :status => 403
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

      aris1 = Article.new
      aris1.id = @params['id'] if @params['id']
      aris1.title = data['title']
      aris1.body = data['body']
      aris1.format = "plain"
      aris1.size = aris1.body.size
      aris1.article_date = Time.now
      aris1.article_mtime = Time.now
      aris1.save
      @article = aris1
      render :status => 201 # 201 Created @ Location
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
      render :text => "dslete #{@params['id']}", :status => 204
    else
      render :text => "no method #{request.method}", :status => 403
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

end
