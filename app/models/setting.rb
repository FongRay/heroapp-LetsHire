class Setting < ActiveRecord::Base
  attr_accessible :ldap_base, :ldap_host, :ldap_port, :mail_password, :mail_user, :smtp_port, :smtp_server
end
