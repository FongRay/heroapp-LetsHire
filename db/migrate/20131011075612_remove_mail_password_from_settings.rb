class RemoveMailPasswordFromSettings < ActiveRecord::Migration
  def up
  	remove_column :settings, :mail_password
  end

  def down
  	add_column :settings, :mail_password, :string
  end
end
