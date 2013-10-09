class SettingsController < ApplicationController
	def edit
		@setting = Setting.find("1")
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
