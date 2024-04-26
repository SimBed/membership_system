class CreateWaivers < ActiveRecord::Migration[7.0]
  def change
    create_table :waivers do |t|
      t.boolean :tear
      t.boolean :pcos
      t.boolean :none
      t.boolean :menopausal
      t.boolean :fertility
      t.boolean :injury
      t.text :injury_note
      t.boolean :heart_trouble
      t.boolean :chest_pain
      t.boolean :doctors_permit
      t.boolean :signed
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end
  end
end
