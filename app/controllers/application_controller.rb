class ApplicationController < ActionController::Base
  protect_from_forgery

  REQUIRE_LOGIN = 'You must be logged in to access this section'
  REQUIRE_ADMIN = 'You must be admin to access this section'
  NO_PERMISSION = 'You do not have permission to access this section'

  # We leverage 'cancan' to achieve authentication and authorization.
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :alert => NO_PERMISSION
  end

  # The UI hack method to initialize the admin account.
  def init
    return redirect_to root_path if User.count > 0
    @user = User.new
    render :file => 'utilities/admin_setup'
  end

  # The CLI hack method to initialize the admin account.
  def admin_setup
    return redirect_to root_path  if User.count > 0
    Department.create(Department::DEFAULT_SET) if Department.count == 0

    it = Department.find_by_name 'IT'
    @user = User.new_admin(params[:user])
    @user.department_id = it.id
    if @user.save
      redirect_to new_user_session_path, :notice => 'Admin user created successfully, enjoy LetsHire '
    else
      redirect_to request.referer, :alert => 'Creating admin user failed, retry'
    end
  end

  private

  def require_login
    unless user_signed_in?
      if request.fullpath == '/'
        redirect_to new_user_session_path
      else
        redirect_to new_user_session_path, :notice => REQUIRE_LOGIN
      end
    end
  end

  def require_admin
    unless current_user and current_user.admin?
      redirect_to root_path, :alert => REQUIRE_ADMIN
    end
  end

  def after_sign_in_path_for(resource)
    root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
