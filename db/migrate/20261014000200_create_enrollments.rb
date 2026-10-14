class CreateEnrollments < ActiveRecord::Migration[8.1]
  def change
    create_table :enrollments do |t|
      t.references :provider, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :client, null: false, foreign_key: { on_delete: :cascade }
      t.string :plan, null: false

      t.timestamps
    end

    add_index :enrollments, [ :provider_id, :client_id ], unique: true
    add_check_constraint :enrollments, "plan IN ('basic', 'premium')", name: "enrollments_plan_check"
  end
end
