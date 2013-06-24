class UsersController < AuthenticatedController
  # We only allow 'admin' user to manage users information.
  before_filter :require_admin, :except => [:index_for_selection, :show]

  def index
    @users = User.include_deleted_in { User.name_order.paginate(:page => params[:page]) }
  end

  def index_for_selection
    @users = []
    # Query users which belong to one specific department, one scenario is that,
    # when we arrange interviews for one job in 'HR' department, we need to assign interviewers
    # who are working at 'HR' department.
    if params[:department_id]
      department = Department.find(params[:department_id])
      @users = department.users.where("name like ?", "%#{params[:q]}%").paginate(:page => params[:page])
    else
      @users = User.active.name_order.where("name like ?", "%#{params[:q]}%").paginate(:page => params[:page])
    end
    render :action => 'index_for_selection', :layout => false
  rescue
    render :action => 'index_for_selection', :layout => false
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      redirect_to users_url
    else
      render :action => 'new'
    end
  end

  def new
    @user = User.new
  end

  def show
    authorize! :read, User
    @user = User.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to users_url, :alert => 'Invalid user'
  end

  def update
    @user = User.active.find(params[:id])

    # required for settings form to submit when password is left blank
    if params[:user][:password].blank?
      params[:user].delete("password")
      params[:user].delete("password_confirmation")
    end

    params[:user].delete("deleted_at")

    if @user.update_attributes(params[:user])
      redirect_to @user
    else
      render :action => 'edit'
    end

  rescue ActiveRecord::RecordNotFound
    redirect_to users_url, :alert => 'Invalid user'
  rescue
    redirect_to users_url, :alert => 'Invalid parameter'
  end

  def edit
    @user = User.active.find(params[:id])
    @departments = Department.all
  rescue ActiveRecord::RecordNotFound
    redirect_to users_url, :alert => 'Invalid user'
  end

  # In our design, we do not delete user physically, what we do is to mark these
  # users to be 'inactive' in database.
  def deactivate
    @user = User.active.find(params[:id])
    if current_user == @user
      return redirect_to :back, :alert => 'Cannot disable yourself'
    end
    active_opening_count = Opening.published.owned_by(@user.id).count
    active_interview_count = @user.interviews.where(Interview.arel_table[:status].not_eq(Interview::STATUS_CLOSED)).count
    items = []
    items << "active openings" if active_opening_count > 0
    items << "active interviews" if active_interview_count > 0
    # To simplify business logic, we forbid to delete user if the user still has active job
    # openings or interviews.
    if items.first
      return redirect_to users_url, :alert => "Cannot disable user assigned with #{items.join(' or ')}."
    end
    # Here it's safe to remove all 'potential interviewers' for this user.
    @user.opening_participants.destroy_all
    toggle(params, false)
  end

  # Move user back to system
  def reactivate
    toggle(params, true)
  rescue
    redirect_to users_url, :alert => 'Invalid user'
  end

  private

  def toggle(params, active)
    @user = User.include_deleted_in { User.find(params[:id]) }
    option = {:deleted_at => (active ? nil : Time.current)}
    if @user.update_without_password(option) && @user.save
      redirect_to users_url
    else
      redirect_to users_url, :alert => "Operation Failed, error = #{@user.errors.inspect}"
    end
  end

end
