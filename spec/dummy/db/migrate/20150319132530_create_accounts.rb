class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :company_name
      t.string :qb_token
      t.string :qb_secret
      t.string :qb_company_id

      t.timestamps null: false
    end
  end
end
