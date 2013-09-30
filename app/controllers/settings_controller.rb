class SettingsController < ApplicationController
	LDAP_PATH = File.join(Rails.root,"config","settings.yml")
	LDAP_CONFIG = YAML.load(File.read(LDAP_PATH))

	def edit
		@setting = Setting.find("1")
		#logger.info("testing...\n#{@setting.mail_password}")
		redirect_to root_path unless current_user.admin?
	end

	def update
		@setting = Setting.find("1")
		if @setting.update_attributes(params[:setting])
			redirect_to root_path, :notice => 'Config successfully'			
		else
			render :action => edit
		end


	end
end
