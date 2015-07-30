class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string :firstname
      t.string :lastname
      t.string :email
      t.string :phone
      t.string :mobile
      t.string :address_1
      t.string :city
      t.string :state
      t.string :zip

      t.timestamps null: false
    end
  end
end
