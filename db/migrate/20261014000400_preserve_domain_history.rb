class PreserveDomainHistory < ActiveRecord::Migration[8.1]
  def up
    add_column :providers, :deactivated_at, :datetime
    add_column :clients, :deactivated_at, :datetime
    add_column :enrollments, :started_at, :datetime
    add_column :enrollments, :ended_at, :datetime

    execute "UPDATE enrollments SET started_at = created_at"
    change_column_null :enrollments, :started_at, false

    remove_index :enrollments, [ :provider_id, :client_id ]
    add_index :enrollments, [ :provider_id, :client_id ], unique: true,
      where: "ended_at IS NULL", name: "index_enrollments_on_active_pair"
    add_index :enrollments, :provider_id

    [ [ :enrollments, :providers ], [ :enrollments, :clients ], [ :journal_entries, :clients ] ].each do |from, to|
      remove_foreign_key from, to
      add_foreign_key from, to, on_delete: :restrict
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Restoring pair uniqueness could discard enrollment history"
  end
end
