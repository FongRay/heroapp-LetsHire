class OpeningsController < ApplicationController

  before_filter :require_login, :except => [:index, :show]
  load_and_authorize_resource :except => [:index, :show]

  include ApplicationHelper

  # GET /openings
  def index
    unless user_signed_in?
      #published openings are returned only
      @openings = Opening.published.order(sort_column('Opening') + ' ' + sort_direction).paginate(:page => params[:page])
      render 'openings/index_anonymous'
    else
      @default_filter = 'My Openings'
      case params[:mode]
      when 'all'
        @default_filter = 'All'
        @openings = Opening.order(sort_column('Opening') + ' ' + sort_direction).paginate(:page => params[:page])
      when 'no_candidates'
        @default_filter = 'Openings with Zero Candidates'
        @openings = Opening.published.without_candidates.owned_by(current_user.id).order(sort_column('Opening') + ' ' + sort_direction).paginate(:page => params[:page])
      when 'owned_by_me'
        @default_filter = 'My Openings'
        @openings = Opening.owned_by(current_user.id).order(sort_column('Opening') + ' ' + sort_direction).paginate(:page => params[:page])
      else
        if can? :manage, Opening
          @openings = Opening.owned_by(current_user.id).order(sort_column('Opening') + ' ' + sort_direction).paginate(:page => params[:page])
        else
          #NOTE: here we get all openings which 'current_user' has interviews on
          @openings = Opening.interviewed_by(current_user.id).paginate(:page => params[:page])
        end
      end
      render 'openings/index'
    end

  end

  # GET /openings/1
  # GET /openings/1.json
  def show
    @opening = Opening.find(params[:id])

    respond_to do |format|
      format.html # _assessment.html.slim
      format.json { render json: @opening }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to openings_url, notice: 'Invalid opening'
  end

  # GET /openings/new
  # GET /openings/new.json
  def new
    @opening = Opening.new(:title => '', :description => description_template)
    @opening.recruiter = current_user if current_user.has_role?(:recruiter)
    if current_user.has_role?(:hiring_manager)
      @opening.hiring_manager_id = current_user.id
      @opening.department_id = current_user.department_id
    end

    respond_to do |format|
      format.html # edit.html.slim
      format.json { render json: @opening }
    end
  end

  # GET /openings/1/edit
  def edit
    @opening = Opening.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to openings_url, notice: 'Invalid opening'
  end

  # POST /openings
  def create
    @opening = Opening.new(params[:opening])

    unless current_user.has_role?(:recruiter)
      return redirect_to openings_url, notice: 'Cannot create Job opening for other hiring managers.' if @opening.hiring_manager_id != current_user.id
    end
    @opening.creator = current_user
    if @opening.save
      redirect_to @opening, notice: 'Opening was successfully created.'
    else
      render action: 'new'
    end
  end

  # PUT /openings/1
  def update
    @opening = Opening.find(params[:id])

    authorize! :manage, @opening
    unless current_user.has_role?(:recruiter)
      params[:opening].delete :recruiter_id
      params[:opening].delete :hiring_manager_id
      params[:opening].delete :department_id
    end
    params[:opening].delete :creator_id

    if @opening.close_operation?(params[:opening][:status])
      # transaction update the related opening_candidates status
      OpeningCandidate.transaction do
        @opening.opening_candidates.each do |opening_candidate|
          opening_candidate.interviews.each do |interview|
            interview.cancel_interview('Job Opening Closed')
          end
          opening_candidate.close_job_application if opening_candidate.in_interview_loop?
        end
      end
    end

    if @opening.update_attributes(params[:opening])
      redirect_to @opening, notice: 'Opening was successfully updated.'
    else
      render action: 'edit'
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to openings_url, notice: 'Invalid opening'
  end

  # POST /openings/1/assign_candidates
  def assign_candidates
    @opening = Opening.find(params[:id])
    authorize! :manage, @opening

    params[:candidates] ||= []
    params[:candidates].each do |candidate|
      opening_candidate = @opening.opening_candidates.where(:candidate_id => candidate).first_or_create
      opening_candidate.update_candidate if opening_candidate
    end
    render :json => { :success => true }
  rescue ActiveRecord::RecordNotFound
    redirect_to openings_url, notice: 'Invalid opening'
  end



  # DELETE /openings/1
  # DELETE /openings/1.json
  def destroy
    @opening = Opening.find(params[:id])
    authorize! :manage, @opening
    if @opening.published? or @opening.closed?
      if current_user.admin?
        @opening.destroy
      else
        #NOTE: only admin user is able to delete published or closed job openings
        raise CanCan::AccessDenied
      end
    else
      @opening.destroy
    end

    redirect_to openings_url
  rescue ActiveRecord::RecordNotFound
    redirect_to openings_url, notice: 'Invalid opening'
  end

  def subregion_options
    render :partial => 'utilities/province_select', :locals => { :container => 'opening' }
  end

  def opening_options
    render :partial => 'opening_selection_combox', :locals => {:selected_department_id => params[:selected_department_id] }
  end


  def interviewers_select
    opening = Opening.find(params[:id])
    mode = params[:mode]
    users = (mode == 'all') ? User.active.all: opening.participants
    render :partial => 'users/user_select', :locals => { :users => users,
                                                         :multiple=> true  }
  rescue
    render :partial => 'users/user_select', :locals => { :users => [] }
  end


  private
  def description_template
        #Fixme: need load from 'setting' page
        <<-END_OF_STRING
About Us

ABC is the world leader in virtualization and cloud infrastructure solutions.
We empower our 400,000 customers by simplifying, automating, and transforming
the way they build, deliver, and consume IT. We are a passionate and innovative
group of people, comprised of thousands of top-notch computer scientists and
software engineers spread across the world.

Job Description
We are seeking ....


Requirements
-	condition 1
-	condition 2

        END_OF_STRING
  end
end
