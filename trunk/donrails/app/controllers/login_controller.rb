class LoginController < ApplicationController
  layout :only => [:login_index, :authenticate]
  before_filter :authorize, :except => [:login_index, :authenticate]

  def login_index
    render_action "index"
  end

  def authorize
    unless @session["person"] == "ok"
      redirect_to :action => "login_index"
    end
  end
  
  def authenticate
    c = @params["nz"]
    namae = c["n"]
    password = c["p"]
    if namae == ADMIN_USER and password == ADMIN_PASSWORD
      @session["person"] = "ok"
    else
      redirect_to :action => "login_index"
    end
    @categories = Category.find_all
  end

  def logout
  end

  def manage_comment
    @comments_pages, @comments = paginate(:comment, :per_page => 30,
                                          :order_by => 'id DESC'
                                          )
  end

  def delete_comment
    c = @params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        b = Comment.find(k.to_i)
        b_art = b.articles
        b.articles.delete(b_art)
        Comment.delete(k.to_i)
      end
    end
    redirect_to :action => "manage_comment"
  end


  def add_article
    c = @params["article"]
    title = c["title"]
    body = c["body"]
    category0 = @params["category0"]
    cat1 = c["category"]
    format = @params["format"]

    get_ymd
    aris1 = Article.new("title" => title,
                        "body" => body,
                        "size" => body.size,
                        "format" => format,
                        "article_date" => @ymd,
                        "article_mtime" => Time.now
                        )

    if category0.size > 0
      ca = category0.to_a
      if cat1
        ca += cat1.split(/\s+/)
      end
    elsif cat1
      ca = cat1.split(/\s+/)
    end

    ca.each do |ca0|
      b = Category.find(:first, :conditions => ["name = ?", ca0])
      if b == nil
        b = Category.new("name" => ca0)
        b.save
      end
      aris1.categories.push_with_attributes(b)
    end
    aris1.save
 
    ca.clear
    c.clear
    redirect_to :action => "manage_article"
  end

  def manage_article
    @articles_pages, @articles = paginate(:article, :per_page => 30,
                                          :order_by => 'id DESC'
                                          )
  end

  def delete_article
    c = @params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        b = Article.find(k.to_i)
        b_cat = b.categories
        b_comment = b.comments

        b.categories.delete(b_cat)
        b.comments.delete(b_comment)
        b.destroy
      end
    end
    redirect_to :action => "manage_article"
  end

  def hnf_save_all
    @articles = Article.find(:all, :order => "article_date")
    rf = hnf_save_date_inner_all
    send_file("/tmp/hnfall.tar.gz", :filename => rf)
    redirect_to :action => 'index'
  end

  def hnf_save_date
    get_ymd
    if @ymd
      @articles = Article.find(:all, :conditions => ["article_date = ?", @ymd])
    else
      render_text = "正しく日付を指定してください"
    end
    inner, hnf_file = hnf_save_date_inner
    send_data(inner, :filename => hnf_file) ## send file OK
    redirect_to :action => 'index'
  end

  def picture_get
    @picture = Picture.new
  end

  def picture_save
    @picture = Picture.new(params[:picture])
    if @picture.save
      render_text "uploaded to #{@picture.path} (#{@picture.size} bytes)"
    else
      render_action :picture_get
    end
  end

end
