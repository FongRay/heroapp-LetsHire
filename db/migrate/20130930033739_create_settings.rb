class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.string :ldap_host
      t.integer :ldap_port
      t.string :ldap_base
      t.string :smtp_server
      t.integer :smtp_port
      t.string :mail_user
      t.string :mail_password

      t.timestamps
    end
  end
end
