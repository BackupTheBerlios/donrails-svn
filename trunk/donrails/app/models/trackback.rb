class Trackback < ActiveRecord::Base
  belongs_to :article
  validates_antispam :url, :ip, :excerpt

  protected
  before_save :kcode_convert
  after_save :notify_by_mail

  def notify_by_mail
    CommentMailer.deliver_notify(excerpt, blog_name)
  end

  def kcode_convert
    if excerpt
      self.excerpt = excerpt.toutf8
    end
    if blog_name
      self.blog_name = blog_name.toutf8
    end
    if title
      self.title = title.toutf8
    end
  end

end
