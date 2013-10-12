class SettingsController < ApplicationController
	def edit
		@setting = Setting.find("1")
		redirect_to root_path unless current_user.admin?
	end

	def update
		@setting = Setting.find("1")
		if @setting.update_attributes(params[:setting])
			ActionMailer::Base.smtp_settings[:address] = Setting.find("1").smtp_server
			ActionMailer::Base.smtp_settings[:port]    = Setting.find("1").smtp_port
			redirect_to root_path, :notice             => 'Config successfully'
		else
			render :action => edit
		end
	end
end
