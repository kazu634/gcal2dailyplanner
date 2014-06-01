class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :event_id, :null => false
      t.string :event, :null => false
      t.string :start, :null => false
      t.string :end, :null => false
      t.string :status, :null => false
      t.string :etag, :null => false
      t.string :link, :null => false
      t.string :event_created, :null => false
      t.string :event_updated, :null => false
      t.string :user_id, :null => false
      t.string :calendar_id, :null => false
      t.timestamps
    end
  end
end
