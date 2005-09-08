class Blacklist < ActiveRecord::Base
  validates_presence_of :format, :pattern
end
