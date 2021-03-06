require 'kconv'

class Comment < ActiveRecord::Base
  has_and_belongs_to_many :articles, :join_table => "comments_articles"

  validates_presence_of :author
  validates_length_of :password, :minimum => 4, :too_short => "pick a longer password"
  validates_length_of :body, :minimum => 5, :too_short => "too short article"

  validates_antispam :url, :ipaddr, :body

  protected
  before_save :kcode_convert, :correct_url, :strip_html_in_body

  def kcode_convert
    if body
      self.body = body.toutf8
    end
    if author
      self.author = author.toutf8
    end
    if title
      self.title = title.toutf8
    end
  end

  def correct_url
    unless url.to_s.empty?
      unless url =~ /^http\:\/\//
        self.url = "http://#{url}"
      end
    end
  end

  def strip_html_in_body
    allow = ['p','br','i','b','u','ul','li']
    allow_arr = allow.join('|') << '|\/'
    body.gsub!(/<(\/|\s)*[^(#{allow_arr})][^>]*>/,'')
  end
end
