class OpeningsController < ApplicationController

  before_filter :require_login, :except => [:index, :show]
  load_and_authorize_resource :except => [:index, :show]

  # GET /openings
  # GET /openings.json
  def index
    unless user_signed_in?
      #published openings are returned only
      #TODO: need exclude certain fields from anonymous access, such as 'Hiring Manager'
      @openings = Opening.published.paginate(:page => params[:page], :order => 'title ASC')
    else
      if params.has_key?(:all)
        @openings = Opening.paginate(:page => params[:page], :order => 'title ASC')
      else
        if can? :manage, Opening
          @openings = Opening.owned_by(current_user.id).paginate(:page => params[:page], :order => 'title ASC')
        else
          @openings = current_user.openings.order('title ASC')
        end
      end
    end

    respond_to do |format|
      format.html  do
        if user_signed_in?
          render "openings/index"
        else
          render "openings/index_anonymous"
        end
      end
      format.json { render json: @openings }
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
    @opening.hiring_manager = current_user if current_user.has_role?(:hiringmanager)

    respond_to do |format|
      format.html # new.html.slim
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
  # POST /openings.json
  def create
    @opening = Opening.new(params[:opening])

    @opening.creator = current_user
    respond_to do |format|
      if @opening.save
        format.html { redirect_to @opening, notice: 'Opening was successfully created.' }
        format.json { render json: @opening, status: :created, location: @opening }
      else
        format.html { render action: "new" }
        format.json { render json: @opening.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /openings/1
  # PUT /openings/1.json
  def update
    @opening = Opening.find(params[:id])

    respond_to do |format|
      if @opening.update_attributes(params[:opening])
        format.html { redirect_to @opening, notice: 'Opening was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @opening.errors, status: :unprocessable_entity }
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to openings_url, notice: 'Invalid opening'
  end

  # DELETE /openings/1
  # DELETE /openings/1.json
  def destroy
    @opening = Opening.find(params[:id])
    @opening.destroy

    respond_to do |format|
      format.html { redirect_to openings_url }
      format.json { head :no_content }
    end
  end

  def subregion_options
    render :partial => 'utilities/province_select', :locals => { :container => 'opening' }
  end


  def opening_options
    render :partial => 'opening_select'
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
