class CreateCalendars < ActiveRecord::Migration
  def change
    create_table :calendars do |t|
      t.string :calid, :null => false
      t.string :calendar, :null => false
      t.string :etag, :null => false
      t.string :timezone, :null => false
      t.string :bgcolor, :null => false
      t.string :fgcolor, :null => false
      t.string :accessrole, :null => false
      t.string :user_id, :null => false
      t.timestamps
    end
  end
end
