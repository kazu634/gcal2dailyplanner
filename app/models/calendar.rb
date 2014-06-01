class Calendar < ActiveRecord::Base
  belongs_to :user
  has_many :events, :dependent => :destroy
  validates :calid, uniqueness: true
end
