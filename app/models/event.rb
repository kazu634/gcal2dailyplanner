class Event < ActiveRecord::Base
  belongs_to :events
  belongs_to :calendar
  validates :event_id, uniqueness: true

  self.per_page = 10
end
