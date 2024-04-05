class CreateLogins < ActiveRecord::Migration[7.0]
  def change
    create_table :logins do |t|
      t.boolean :by_cookie, default: false
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
