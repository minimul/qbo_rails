class CreateQboErrors < ActiveRecord::Migration
  def change
    create_table :qbo_errors, force: true do |t|
      t.string :message
      t.text :body
      t.string :resource_type, limit: 100 
      t.integer :resource_id
      t.text :request_xml
      t.timestamps :null => false
    end
  end
end
