require 'kconv'

class LoginController < ApplicationController
  before_filter :authorize, :except => [:login_index, :authenticate]

  def login_index
    render_action "index"
  end

  def authorize
    unless @session["person"] == "ok"
      redirect_to :action => "login_index"
    end
    @response.headers["X-donrails"] = "login"
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
    retval = Article.find_by_sql("SELECT format, count(*) AS num FROM articles GROUP BY format ORDER BY num DESC")
    if retval.nil? || retval.empty? then
      @defaultformat = 'plain'
    else
      @defaultformat = retval[0].format
    end
  end

  def logout
    @session["person"] = "logout"
    redirect_to :action => "login_index"
  end

  ## trackback
  def manage_trackback
    @trackbacks_pages, @trackbacks = paginate(:trackback, :per_page => 30,
                                              :order_by => 'id DESC')
  end

  def delete_trackback
    begin
      c = @params["deleteid"]
      c.each do |k, v|
        if v.to_i == 1
          Trackback.delete(k.to_i)
        end
      end
    rescue
      @heading = 'fail delete_trackback'
    end
    redirect_to :action => "manage_trackback"
  end

  ## comment
  def manage_comment
    @comments_pages, @comments = paginate(:comment, :per_page => 30,
                                          :order_by => 'id DESC')
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

  def form_article
    @article = Article.find(@params['pickid'].to_i)
  end

  def fix_article
    c = @params["article"]
    format = @params["format"]
    title = c["title"]
    body = c["body"]
    id = c["id"].to_i
    aris = Article.find(id)
    aris.title = title
    aris.body = body
    aris.format = format
    aris.save
    redirect_to :action => "manage_article"
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
    c = @params["deleteid"].nil? ? [] : @params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        b = Article.find(k.to_i)
        b_cat = b.categories
        b.categories.delete(b_cat)

        b_comment = b.comments
        b_comment.each do |bc|
          Comment.destroy(bc.id)
        end
        b.comments.delete(b_comment)
        b.destroy
      end
    end
    redirect_to :action => "manage_article"
  end

  def manage_blacklist
    @blacklists_pages, @blacklists = paginate(:blacklist, :per_page => 30,
                                          :order_by => 'id DESC'
                                          )
  end

  def delete_blacklist
    c = @params["deleteid"].nil? ? [] : @params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        b = Blacklist.find(k.to_i)
        b.destroy
      end
    end
    redirect_to :action => "manage_blacklist"
  end

  def add_blacklist
    c = @params["blacklist"]
    aris1 = Blacklist.new("pattern" => c["pattern"],
                          "format" => @params["format"])
    aris1.save
    redirect_to :action => "manage_blacklist"
  end

  ## ping
  def manage_ping
    @pings_pages, @pings = paginate(:ping,:per_page => 30,:order_by => 'id DESC')
  end
  

  ## blogping
  def manage_blogping
    @blogpings_pages, @blogpings = paginate(:blogping,:per_page => 30,:order_by => 'id DESC')
  end

  def delete_blogping
    c = @params["deleteid"].nil? ? [] : @params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        b = Blogping.find(k.to_i)
        b.destroy
      end
    end
    redirect_to :action => "manage_blogping"
  end

  def add_blogping
    c = @params["blogping"]
    aris1 = Blogping.new("server_url" => c["server_url"])
    aris1.save
    redirect_to :action => "manage_blogping"
  end


  # author
  def manage_author
    @authors_pages, @authors = paginate(:author, :per_page => 30,
                                          :order_by => 'id DESC'
                                          )
  end

  def delete_unwrite_author
    c = @params["unwriteid"].nil? ? [] : @params["unwriteid"]
    c.each do |k, v|
      if v.to_i == 1
        b = Author.find(k.to_i)
        if b.writable == 1
          b.writable = 0
          b.save
        end
      end
    end
    c = @params["deleteid"].nil? ? [] : @params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        b = Author.find(k.to_i)
        b.destroy
      end
    end
    redirect_to :action => "manage_author"
  end

  def add_author
    c = @params["author"]
    aris1 = Author.new("name" => c["name"],
                       "pass" => c["pass"],
                       "writable" => 1)
    aris1.save
    redirect_to :action => "manage_author"
  end

  def hnf_save_all
    @articles = Article.find(:all, :order => "article_date")
    rf = hnf_save_date_inner_all
    fftmp = open("/tmp/hnfall.tgz", "r")
    send_data(fftmp.read, :filename => rf)
    fftmp.close
  end

  def hnf_save_date
    get_ymd
    if @ymd
      @articles = Article.find(:all, :conditions => ["article_date = ?", @ymd])
    else
      render_text = "please input date w/valid format."
    end
    inner, hnf_file = hnf_save_date_inner
    send_data(inner, :filename => hnf_file) ## send file OK
    redirect_to :action => 'index'
  end

  def hnf_save_date_inner_all
    firstday = @articles.first.article_date.to_date.to_s.gsub('-','')
    lastday = @articles.last.article_date.to_date.to_s.gsub('-','')
    hnf_tar_file_name = "hnf-#{firstday}_#{lastday}.tgz"

    if File.exist? "/tmp/hnfall.tgz"
      File.delete "/tmp/hnfall.tgz"
    end

    day0 = Time.new
    day1 = day0
    hnfbody = "OK \n\n"
    Dir.mkdir("/tmp/.donrails-tmp") unless FileTest.exist? "/tmp/.donrails-tmp"
    predir = "/tmp/.donrails-tmp/" + Process.pid.to_s 
    Dir.mkdir(predir) unless FileTest.exist? predir
    @articles.each do |article|
      day0 = article.article_date.to_date 
      if day1 != day0
        ymd2 = day1.to_date.to_s.gsub('-','')
        hnf_file = "#{predir}/d#{ymd2}.hnf"
        unless hnfbody == "OK \n\n"
          tmpf = File.new(hnf_file, "w")
          tmpf.puts Kconv.toeuc(hnfbody)
          tmpf.close
        end

        day1 = article.article_date.to_date 
        hnfbody = "OK \n\n"
      end 
      
      hnfbody += 'CAT '
      article.categories.each do |cat|
        hnfbody += cat.name 
      end 
      hnfbody += "\n"

      if article.title
        if article.title =~ /^https?:\/\// 
          hnfbody += "LNEW "
        else
          hnfbody += "NEW "
        end
        hnfbody += article.title + "\n" 
      end
      hnfbody += article.body + "\n"
    end
    system("cd #{predir} && tar zcf /tmp/hnfall.tgz *.hnf")
    return hnf_tar_file_name
  end

  def hnf_save_date_inner
    day0 = Time.new
    day1 = day0
    hnfbody = "OK \n\n"
    @articles.each do |article|
      day0 = article.article_date.to_date 
      if day1 != day0 
        day1 = article.article_date.to_date 
      end 
      
      hnfbody += 'CAT '
      article.categories.each do |cat|
        hnfbody += cat.name 
      end 
      hnfbody += "\n"

      if article.title =~ /^https?:\/\// 
        hnfbody += "LNEW "
      else
        hnfbody += "NEW "
      end
      hnfbody += article.title + "\n"
      hnfbody += article.body + "\n"
    end
    ymd2 = day0.to_date.to_s.gsub('-','')
    hnf_file = "d#{ymd2}.hnf"
    return hnfbody, hnf_file
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
