class CreateProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :providers do |t|
      t.string :name, null: false
      t.string :email, null: false

      t.timestamps
    end
  end
end
