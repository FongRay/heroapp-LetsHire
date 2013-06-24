class ProfileController < AuthenticatedController

  def edit
    @user = current_user
    redirect_to root_path unless @user
  end

  def update
    @user = User.active.find(current_user.id)

    safe_params = {}
    [:current_password, :password, :password_confirmation].each do | key |
      safe_params[key] = params[:user][key]
    end

    if @user.update_with_password(safe_params)
      sign_in @user, :bypass => true
      redirect_to root_path, :notice => 'Reset Password successfully'
    else
      render 'edit'
    end
  end

  # From long-term perspective, we might need to provide a way to reset user's password
  # through user's email.
end
