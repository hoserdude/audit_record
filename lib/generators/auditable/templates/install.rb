class <%= migration_class_name %> < ActiveRecord::Migration
  def change
    create_table :audit_records do |t|
      t.integer :user_id, :allow_nil => false
      t.string :action
      t.text :modifications
      t.string :remote_address
      t.string :auditable_type
      t.integer :auditable_id
      t.timestamps
    end
    add_index :audit_records, :user_id
    add_index :audit_records, [:auditable_id, :auditable_type]
  end
end