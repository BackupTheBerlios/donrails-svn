class ArticleSweeper < ActionController::Caching::Sweeper
  observe Article, Category

  def after_save(record)
    expire_for(record)
  end

  def after_destroy(record)
    expire_for(record)
  end

  def expire_for(record)
    case record
    when Article
      expire_action(:controller => 'notes', :action => %w(recent_category_title_a recent_trigger_title_a category_select_a pick_article_a pick_article_a2))

      expire_page(:controller => 'notes', :action => %w(index rdf_recent articles_long))

      expire_page(:controller => 'notes', :action => 'noteslist')
      begin
        ppdir = RAILS_ROOT + "/public/notes/d/page"
        ppdir2 = Dir.entries(ppdir)
        ppdir2.each do |x|
          if x =~ /(\d+).html/
            expire_page(:controller => 'notes', :action => 'noteslist', :page => $1)
          end
        end
      rescue Errno::ENOENT
      rescue
        p $!
      end

      expire_page(:controller => 'notes', :action => 'articles_long')
      begin
        ppdir = RAILS_ROOT + "/public/notes/articles_long/d/page"
        ppdir2 = Dir.entries(ppdir)
        ppdir2.each do |x|
          if x =~ /(\d+).html/
            expire_page(:controller => 'notes', :action => 'articles_long', :page => $1)
          end
        end
      rescue Errno::ENOENT
      rescue
        p $!
      end

      expire_page(:controller => 'notes', :action => %w(rdf_article show_title), :id => record.id)
      #      expire_page(:controller => 'notes', :action => %w(pick_article), :pickid => record.id)
      expire_page(:controller => 'notes', :action => %w(rdf_article show_title2), :title => record.title)

      clall = Category.find_all
      clall.each do |rc|
        expire_page(:controller => 'notes', :action => %w(rdf_category show_category show_category_noteslist) , :category => rc.name)

        begin
          ppdir = RAILS_ROOT + "/public/notes/rdf_category/#{rc.name}/page"
          ppdir2 = Dir.entries(ppdir)
          ppdir2.each do |x|
            if x =~ /(\d+)/
              expire_page(:controller => 'notes', :action => 'rdf_category', :page => $1, :category => rc.name)
            end
          end
        rescue Errno::ENOENT
        rescue
          p $!
        end
        begin
          ppdir = RAILS_ROOT + "/public/notes/category/#{rc.name}/page"
          ppdir2 = Dir.entries(ppdir)
          ppdir2.each do |x|
            if x =~ /(\d+)/
              expire_page(:controller => 'notes', :action => 'category', :page => $1, :category => rc.name)
            end
          end
        rescue Errno::ENOENT
        rescue 
          p $!
        end
      end

      expire_page(:controller => 'notes', :action => 'show_month', :year => record.article_date.year, :month => record.article_date.month)
      expire_page(:controller => 'notes', :action => 'show_nnen', :day => record.article_date.day, :month => record.article_date.month)
      expire_page(:controller => 'notes', :action => 'show_date', :day => record.article_date.day, :month => record.article_date.month, :year => record.article_date.year)

    end
  end

end
