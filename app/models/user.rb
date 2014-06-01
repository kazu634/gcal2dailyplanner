class User < ActiveRecord::Base
  has_many :calendars, :dependent => :destroy
  has_many :events, :dependent => :destroy
  validates :uid, uniqueness: true
end
