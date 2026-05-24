class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.text :content, null: false
      t.integer :rating, null: false

      t.timestamps
    end

    add_index :comments,
              [:user_id, :event_id],
              unique: true
  end
end