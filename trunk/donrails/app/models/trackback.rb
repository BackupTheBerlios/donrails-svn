class Trackback < ActiveRecord::Base
  belongs_to :article
  validates_antispam :url, :ip, :excerpt
end
