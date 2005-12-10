require 'rexml/document'

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
        xml, data = atom_input_parse(request.raw_post)
        aris1 = Article.new
        aris1.id = @params['id'] if @params['id']
        atom_update_article(aris1, data, xml)
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
        xml, data = atom_input_parse(request.raw_post)
        aris1 = Article.find(@params['id'])
        atom_update_article(aris1, data, xml)
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
