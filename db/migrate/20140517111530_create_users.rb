class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :uid, :null => false
      t.string :name, :null => false
      t.string :token, :null => false
      t.string :refresh_token, :null => false
      t.integer :expires_at, :null => false
      t.timestamps
    end
  end
end
