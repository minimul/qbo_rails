class AddQboIdToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :qbo_id, :integer
  end
end
