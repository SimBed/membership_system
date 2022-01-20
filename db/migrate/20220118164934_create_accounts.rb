class CreateAccounts < ActiveRecord::Migration[6.1]
  def change
    create_table :accounts do |t|
      t.string :email
      t.boolean :admin, default: false
      t.boolean :client, default: false
      t.boolean :instructor, default: false
      t.string :password_digest
      t.string :remember_digest
      t.boolean :activated, default: false
      t.string :reset_digest
      t.datetime :reset_sent_at

      t.timestamps
    end
    add_index :accounts, :email, unique: true
  end
end
