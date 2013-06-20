#NOTE: Currently we do not show departments management on web ui, but
#someday we might need this on be visible, so we keep code here.
class DepartmentsController < AuthenticatedController
  before_filter :require_admin, :except => [:user_select, :show]
  # GET /departments
  def index
    @departments = Department.all

  end

  # GET /departments/1
  def show
    @department = Department.find(params[:id])

  end

  # GET /departments/new
  def new
    @department = Department.new
  end

  # GET /departments/1/edit
  def edit
    @department = Department.find(params[:id])
  end

  def user_select
    @department = Department.find(params[:id])
    users = @department.users.active
    role = params[:role] || 'interviewer'
    users.select! { |user| (user.has_role?(role)) }
    render :partial => 'users/user_select', :locals => { :users => users}
  rescue
    render :partial => 'users/user_select', :locals => { :users => [] }
  end

  # POST /departments
  def create
    @department = Department.new(params[:department])

    if @department.save
      redirect_to @department, notice: 'Department was successfully created.'
    else
      render action: "new"
    end

  end

  # PUT /departments/1
  def update
    @department = Department.find(params[:id])

    if @department.update_attributes(params[:department])
      redirect_to @department, notice: 'Department was successfully updated.'
    else
      render action: "edit"
    end
  end

  # DELETE /departments/1
  def destroy
    @department = Department.find(params[:id])
    return redirect_to departments_url, :alert => 'Department with users cannot be deleted.' if @department.users.count > 0
    @department.destroy

    redirect_to departments_url
  end
end
