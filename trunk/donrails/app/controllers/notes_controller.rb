require 'kconv'
class NotesController < ApplicationController
  layout "notes", :except => [
    :pick_article_a,
    :rdf_recent
  ]

  def index
    dateparse
    recent
    @heading = "index"
  end

  def search
    @articles = Article.search(@params["q"])
    @heading = "#{@params["q"]}"
  end
  
  def pick_article
    @articles = Article.find(@params['pickid'].to_i)
    @heading = @articles.title
    recent
  end

  def pick_article_a
    @headers["Content-Type"] = "text/html; charset=utf-8"
    @articles = Article.find(@params['pickid'].to_i)
  end

  def dateparse
    @params.keys.each do |k|
      if k =~ /(\d\d\d\d)(\d\d)a/
        redirect_to :action => "tendays", :year => $1, :month => $2, :day => "01"
      elsif k =~ /(\d\d\d\d)(\d\d)b/
        redirect_to :action => "tendays", :year => $1, :month => $2, :day => "11"
      elsif k =~ /(\d\d\d\d)(\d\d)c/
        redirect_to :action => "tendays", :year => $1, :month => $2, :day => "21"
      end
    end
  end

  def noteslist
    @articles_pages, @articles = paginate(:article, :per_page => 30,
                                          :order_by => 'article_date DESC, id DESC'
                                          )
    @heading = "#{@articles.first.title} at #{@articles.first.article_date.to_date}"
    recent
  end

  def parse_nums
    nums = @params['nums'] if @params['nums'] 

    @notice = nums
    if nums =~ /(\d\d\d\d)(\d\d)(\d\d)/
      redirect_to :action => "show_date", :year => $1, :month => $2, :day => $3
    end

    if nums =~ /(\d+)-(\d+)-(\d+)/
      redirect_to :action => "show_date", :year => $1, :month => $2, :day => $3
    end

    if nums =~  /(\d\d\d\d)-?(\d\d)-?(\d\d)\.html/
      redirect_to :action => "show_date", :year => $1, :month => $2, :day => $3
    end

    @notice = "正しく日付を指定してください" unless @notice
    redirect_to :action => 'noteslist', :notice => @notice
  end

  def rdf_recent
    @recent_articles = Article.find(:all, :order => "id DESC", :limit => 10)
  end

  def rdf_recent2
    @recent_articles = Article.find(:all, :order => "id DESC", :limit => 10)
  end

  def recent
    @recent_articles = Article.find(:all, :order => "id DESC", :limit => 10)
    @recent_road_articles = recent_category("road")
    @recent_ruby_articles = recent_category("ruby")
    @recent_comments = Comment.find(:all, :order => "id DESC", :limit => 10)
  end

  def recent_category(category)
    categories = Category.find(:first, :conditions => ["name = ?", category])
    articles = categories.articles
    return articles.reverse!
  end

  def show_date
    get_ymd
    if @ymd
      @articles_pages, @articles =  paginate(:article, :per_page => 30,
                                             :conditions => ["article_date >= ? AND article_date < ?", @ymd, @ymd1a]
                                             )
    else
      render_text = "正しく日付を指定してください"
    end
    recent
    begin
      @heading = "#{@articles.first.title} at #{@articles.first.article_date.to_date}"
      render_action 'noteslist'
    rescue
      @notice = "The specified article doesn't exist. The latest articles are displayed."
      redirect_to :action => 'noteslist', :notice => @notice
    end
  end
  alias :oneday :show_date 

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

  def hnf_save_date_inner_all
    if File.exist? "/tmp/hnfall.tar.gz"
      File.delete "/tmp/hnfall.tar.gz"
    end
    firstday = @articles.first.article_date.to_date.to_s.gsub('-','')
    lastday = @articles.last.article_date.to_date.to_s.gsub('-','')
    hnf_tar_file_name = "hnf-#{firstday}_#{lastday}.tar.gz"

    day0 = Time.new
    day1 = day0
    hnfbody = "OK \n\n"
    predir = "/tmp/" + Process.pid.to_s 
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

      if article.title =~ /^https?:\/\// 
        hnfbody += "LNEW "
      else
        hnfbody += "NEW "
      end
      hnfbody += article.title + "\n"
      hnfbody += article.body + "\n"
    end
    system("cd #{predir} && tar zcf /tmp/hnfall.tar.gz *.hnf")
    return hnf_tar_file_name
  end
  
  def show_title
    @articles_pages, @articles =  paginate(:article, :per_page => 30, :conditions => ["title = ?", @params['title']])
    if @articles.size >= 1
      @heading = "#{@articles.first.title}"
      cid = @articles.first.id
      begin
        @lastarticle = Article.find(cid - 1)
      rescue
      end
      begin
        @nextarticle = Article.find(:first, :conditions => ["id > ?", cid])
      rescue
      end
      recent
    end
  end

  def show_category
    @category = Category.find(:first, :conditions => ["name = ?", @params['category']])
    @articles_pages, @articles = 
      paginate(:article, 
               :order_by => 'articles.article_date DESC',
               :per_page => 30, 
               :join => "JOIN categories_articles on (categories_articles.article_id=articles.id and categories_articles.category_id=#{@category.id})"
               )
    @heading = "カテゴリ:#{@params['category']}"
    recent
  end

  def afterday
    @debug_oneday = @request.request_uri
    get_ymd
    if @ymd
      @articles_pages, @articles =  paginate(:article, :per_page => 30,
                                             :conditions => ["article_date >= ?", @ymd]
                                             )
      @heading = "#{@articles.first.title}"

      @notice = "#{@articles.first.article_date.to_date} 以降の記事を表示します。"
      render_action 'noteslist'
    else
      render_text "please select only one day"
    end
    recent
  end

  def tendays
    @debug_oneday = @request.request_uri
    get_ymd

    @articles = Article.find(:all,
                             :conditions => ["article_date >= ? AND article_date < ?", @ymd, @ymd10a]
                                           )
    if @articles.size > 0
      @heading = "#{@articles.first.title}"
    
      @notice = "#{@articles.first.article_date.to_date} 以降の10日間の記事を表示します。"
    else
      @notice = "記事がありません。"
    end
    recent
    render_action 'noteslist'
  end

  def add_comment2
    c = @params["comment"]
    author = c["author"]
    password = c["password"]
    url = c["url"]
    title = c["title"]
    body = c["body"]
    article_id = c["article_id"].to_i

    aris1 = Comment.new("password" => password,
                        "date" => Time.now,
                        "title" => title,
                        "author" => author,
                        "url" => url,
                        "ipaddr" => @request.remote_ip,
                        "body" => body
                        )
    a = Article.find(article_id)
    aris1.articles.push_with_attributes(a)
    if aris1.save
      redirect_to :action => "pick_article", :pickid => article_id
    else
      redirect_to :action => "noteslist"
    end
  end

  def picture_get
    @picture = Picture.new
  end


  protected
  def authenticate
    unless @session["person"]
      redirect_to :controller => "login", :action => "login_index"
      return false
    end
  end


end
