require 'kconv'
class NotesController < ApplicationController
  after_filter :add_cache_control

  layout "notes", :except => [
    :pick_article_a,
    :pick_article_a2,
    :recent_category_title_a,
    :recent_trigger_title_a,
    :rdf_recent,
    :rdf_article,
    :rdf_search,
    :rdf_category,
    :trackback,
    :catch_ping,
    :category_select_a,
    :comment_form_a
  ]

  def index
    dateparse
    recent
    @heading = "index"
  end

  def search
    @articles = Article.search(@params["q"])
    @heading = @params["q"]
    @noindex = true
    @lm = Time.now.gmtime
  end

  def show_search_noteslist
    search
    @rdf_category = @params['q']
    @heading = "検索結果:#{@params['q']}"
    render_action 'noteslist'
  end

  def pick_article
    @articles = Article.find(@params['pickid'].to_i)
    @heading = @articles.title
    @lm = @articles.article_mtime.gmtime
  end

  def pick_article_a
    @headers["Content-Type"] = "text/html; charset=utf-8"
    @articles = Article.find(@params['pickid'].to_i)
    @lm = @articles.article_mtime.gmtime
  end

  def pick_article_a2
    @headers["Content-Type"] = "text/html; charset=utf-8"
    @articles = Article.find(@params['pickid'].to_i)
    @lm = @articles.article_mtime.gmtime
  end

  def comment_form_a
    @headers["Content-Type"] = "text/html; charset=utf-8"
    @article = Article.find(@params['id'].to_i)
    @lm = @article.article_mtime.gmtime
  end

  def articles_long
    @articles_pages, @articles = paginate(:article, :per_page => 10,
                                          :order_by => 'size DESC, id DESC'
                                          )
    @heading = "記事サイズ順の表示"
    @noindex = true
    render_action 'noteslist'
  end

  def indexabc
    k = @params['nums']
    if k =~ /(\d\d\d\d)(\d\d)a/
        redirect_to :action => "tendays", :year => $1, :month => $2, :day => "01"
    elsif k =~ /(\d\d\d\d)(\d\d)b/
        redirect_to :action => "tendays", :year => $1, :month => $2, :day => "11"
    elsif k =~ /(\d\d\d\d)(\d\d)c/
        redirect_to :action => "tendays", :year => $1, :month => $2, :day => "21"
    end
  end

  def dateparse
    @params.keys.each do |k|
      if k =~ /(\d\d\d\d)(\d\d)a/
        redirect_to :action => "tendays", :year => $1, :month => $2, :day => "01"
      elsif k =~ /(\d\d\d\d)(\d\d)b/
        redirect_to :action => "tendays", :year => $1, :month => $2, :day => "11"
      elsif k =~ /(\d\d\d\d)(\d\d)c/
        redirect_to :action => "tendays", :year => $1, :month => $2, :day => "21"
      elsif k =~ /([01]\d)([0-3]\d)/
        redirect_to :action => "show_nnen", :month => $1, :day => $2
      end
    end
  end
  protected :dateparse

  def noteslist
    @lm = Article.find(:first, :order => 'article_mtime DESC').article_mtime.gmtime
    minTime = Time.rfc2822(@request.env["HTTP_IF_MODIFIED_SINCE"]) rescue nil
    if minTime and @lm <= minTime
      # use cached version
      render_text '', '304 Not Modified'
    else
      @articles_pages, 
      @articles = paginate(:article, :per_page => 30,
                           :order_by => 'article_date DESC, id DESC'
                           )
      if @articles.empty? then
        @heading = ""
      else
        @heading = "#{@articles.first.title} at #{@articles.first.article_date.to_date}"
      end
      @notice = @params['notice'] unless @notice
    end
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
    @recent_articles = Article.find(:all, :order => "id DESC", :limit => 20)
    @lm = @recent_articles.first.article_mtime.gmtime
  end

  def rdf_recent2
    @recent_articles = Article.find(:all, :order => "id DESC", :limit => 20)
    @lm = @recent_articles.first.article_mtime.gmtime
  end

  def rdf_article
    @article = Article.find(@params['id'])
    @rdf_article = @article.id
    @lm = @article.article_mtime.gmtime
  end

  def rdf_search
    @lm = Time.now.gmtime
    @recent_articles = Article.search(@params["q"])
    @rdf_search = @params["q"]
    if @recent_articles == nil
      render_text "no entry"
    end
  end

  def rdf_category
    @category = Category.find(:first, :conditions => ["name = ?", @params['category']])
    if @category == nil
      @params["q"] = @params["category"]
      redirect_to :action => 'rdf_search', :q => @params["category"]
    else
      @recent_articles_pages, 
      @recent_articles = paginate(:article, :per_page => 20,
                                  :order_by => 'id DESC',
                                  :join => "JOIN categories_articles on (categories_articles.article_id=articles.id and categories_articles.category_id=#{@category.id})"
                                  )
      @rdf_category = @category.name
      @lm = @recent_articles.first.article_mtime.gmtime
    end
  end

  def recent
    @lm = @recent_articles.first.article_mtime.gmtime
    @recent_articles = Article.find(:all, :order => "id DESC", :limit => 10)
    @recent_comments = Article.find(:all, :order => "articles.article_date DESC", :limit => 30,
                                    :joins => "JOIN comments_articles on (comments_articles.article_id=articles.id)"
                                   )

    @rt = Article.find(:all, 
                       :order => "articles.article_date DESC", 
                       :limit => 30,
                       :joins => "JOIN trackbacks on (trackbacks.article_id=articles.id)"
                       )
    aid = Array.new
    @rt.each do |rt|
      aid.push rt.article_id
    end
    @recent_trackbacks = Article.find(aid)
    @long_articles = Article.find(:all, :order => "size DESC", :limit => 10)
  end
  private :recent

  def recent_category(category)
    categories = Category.find(:first, :conditions => ["name = ?", category])
    return [] if categories.nil?
    articles = categories.articles
    return articles.reverse!
  end
  private :recent_category

  def recent_trigger_title_a
    @headers["Content-Type"] = "text/html; charset=utf-8"
    if @params['trigger'] == 'recents'
      @articles = Article.find(:all, :order => "id DESC", :limit => 10)
    elsif @params['trigger'] == 'trackbacks'
      @articles = Article.find(:all, :order => "articles.article_date DESC", :limit => 30, :joins => "JOIN trackbacks on (trackbacks.article_id=articles.id)")
    elsif @params['trigger'] == 'comments'
      @articles = Article.find(:all, :order => "articles.article_date DESC", :limit => 30, :joins => "JOIN comments_articles on (comments_articles.article_id=articles.id)")
    elsif @params['trigger'] == 'long'
      @articles = Article.find(:all, :order => "size DESC", :limit => 10)
    end
    @lm = @articles.first.article_mtime.gmtime
  end

  def recent_category_title_a
    @headers["Content-Type"] = "text/html; charset=utf-8"
    if @params['category']
      categories = Category.find(:first, :conditions => ["name = ?", @params['category']])
      return [] if categories.nil?
      @articles = categories.articles.reverse
      @lm = @articles.first.article_mtime.gmtime
    end
  end

  def category_select_a 
    @headers["Content-Type"] = "text/html; charset=utf-8"
    @categories = Category.find_all
  end

  def show_month
    get_ymd
    if @ymd
      @articles_pages, @articles =  paginate(:article, :per_page => 30,
                                             :conditions => ["article_date >= ? AND article_date < ?", @ymd, @ymd31a]
                                             )
    end
    @heading = "#{@articles.first.article_date.to_date} - #{@articles.last.article_date.to_date}"
    @noindex = true
    render_action 'noteslist'
  end

  def show_nnen
    if (@params["day"] and @params["month"])
      ymdnow = convert_ymd("#{Time.now.year}-#{@params["month"]}-#{@params["day"]}")
    end
    
    if ymdnow =~ /(\d\d\d\d)-(\d\d)-(\d\d)/
      t2 = Time.local($1,$2,$3)
    end
    t3 = t2
    @articles = Article.find(:all, :order => "id DESC", :conditions => ["article_date >= ? AND article_date < ?", t2, t2.tomorrow])
    for i in 1..10
      t2 = t2.last_year
      i += 1
      @articles += Article.find(:all, :order => "id DESC", :conditions => ["article_date >= ? AND article_date < ?", t2, t2.tomorrow])
    end
    @notice = "#{t2.month}月 #{t2.day}日の記事(#{@articles.first.article_date.year}年から#{@articles.last.article_date.year}年まで)"
    @noindex = true
    render_action 'noteslist'
  end

  def show_date
    get_ymd
    if @ymd
      @articles_pages, @articles =  paginate(:article, :per_page => 30,
                                             :conditions => ["article_date >= ? AND article_date < ?", @ymd, @ymd1a]
                                             )
    else
      @noindex = true
      render_text = "正しく日付を指定してください"
    end

    begin
      @heading = "#{@articles.first.title} at #{@articles.first.article_date.to_date}"
      render_action 'noteslist'
    rescue
      @notice = "指定された記事はありません。代わりに最近の記事から表示します。"
      @noindex = true
      redirect_to :action => 'noteslist', :notice => @notice
    end
  end
  alias :oneday :show_date 
  
  def show_title
    if @params['id']
      @articles_pages, @articles =  paginate(:article, :per_page => 30, :conditions => ["id = ?", @params['id']]) 
    elsif @params['title'].size > 0
      @articles_pages, @articles =  paginate(:article, :per_page => 30, :conditions => ["title = ?", @params['title']]) 
    end
    @lm = @articles.first.article_mtime.gmtime

    if @articles.size >= 1
      @heading = "#{@articles.first.title}"
      cid = @articles.first.id
      @rdf_article = @articles.first.id
      begin
        @lastarticle = Article.find(cid - 1)
      rescue
      end
      begin
        @nextarticle = Article.find(:first, :conditions => ["id > ?", cid])
      rescue
      end
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
    @lm = @articles.first.article_mtime.gmtime
  end

  def show_category_noteslist
    show_category
    @rdf_category = @params['category']
    @heading = "カテゴリ:#{@params['category']}"
    render_action 'noteslist'
  end

  def afterday
    @noindex = true
    @debug_oneday = @request.request_uri
    get_ymd
    if @ymd
      @articles =  Article.find(:all, :limit => 30,
                                :conditions => ["article_date >= ?", @ymd])
      if @articles.first
        @heading = "#{@articles.first.title}"
        @notice = "#{@articles.first.article_date.to_date} 以降 30件の記事を表示します。"
        render_action 'noteslist'
      else
        @notice = "#{@ymd}以降に該当する記事はありません"
        render_action 'noteslist', 404
      end
    else
      render_text "please select only one day", 404
    end
  end

  def tendays
    @debug_oneday = @request.request_uri
    get_ymd
    @noindex = true
    @articles = Article.find(:all,
                             :conditions => ["article_date >= ? AND article_date < ?", @ymd, @ymd10a]
                                           )
    if @articles.size > 0
      @lm = @articles.first.article_mtime.gmtime
      @heading = "#{@articles.first.title}"
    
      @notice = "#{@articles.first.article_date.to_date} 以降の10日間の記事を表示します。"
      render_action 'noteslist'
    else
      @notice = "該当する記事はありません"
      render_action 'noteslist', 404
    end
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

  def trackback
    if request.method == :post
      begin
        unless (@params.has_key?('url') and @params.has_key?('id'))
          @catched = false
          @message = 'need url and id '
        end
        article = Article.find(@params['id'])

        unless article
          @catched = false
          @message = 'need valid id '
        end

        if @catched != false
          tb = Trackback.new
          tb.article_id = article.id
          tb.category = @params['category'] if @params['category'] 
          tb.blog_name = @params['blog_name'] if @params['blog_name']
          tb.title = @params['title'] || @params['url']
          tb.excerpt = @params['excerpt'] if @params['excerpt']
          tb.url = @params['url']

          tb.ip = request.remote_ip
          tb.created_at = Time.now
          tb.save
          @catched = true
          @message = 'success'
        end
      rescue
        @catched = false
        @message = $!
      end
    else
      @catched = false
      @message = 'Please use HTTP POST'
    end
  end


  def catch_ping
    if request.method == :post
      category = @params['category'] if @params['category'] 
      blog_name = @params['blog_name'] if @params['blog_name']
      title = @params['title'] || @params['url']
      excerpt = @params['excerpt'] if @params['excerpt']
      url = @params['url']
      
      ip = request.remote_ip
      created_at = Time.now
      @catched = true
#      render_text 'success'
    else
      @catched = false
#      render_text 'Please use HTTP POST', 404
    end
  end

  protected
  def authenticate
    unless @session["person"]
      redirect_to :controller => "login", :action => "login_index"
      return false
    end
  end

  def add_cache_control
    if @lm
      @headers['Last-Modified'] = @lm.rfc2822.to_s
    end
    if @noindex
      @headers['Cache-Control'] = 'max-age=86400'
    else
      @headers['Cache-Control'] = 'public'
    end
  end

end
