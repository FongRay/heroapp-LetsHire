ActionMailer::Base.smtp_settings = {
	:address              => Setting.find("1").smtp_server,
	:port                 => Setting.find("1").smtp_port,
	:authentication       => "plain",
	:enable_starttls_auto => true
}

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.perform_deliveries = true