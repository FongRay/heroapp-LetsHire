class AssessmentsController < ApplicationController
  before_filter { authorize! :manage, Candidate }
  def new
    @opening_candidate = OpeningCandidate.find params[:opening_candidate_id]
    if @opening_candidate
      @assessment = Assessment.new(:opening_candidate_id => @opening_candidate.id)
      render 'assessments/edit'
    else
      redirect_to candidates_url, :notice => "The parent doesn't exist anymore"
    end
  end


  # GET /opening_candidates/:opening_candidate_id/assessments/:id/edit
  def edit
    @assessment = Assessment.find(params[:id])

    raise ActiveRecord::RecordNotFound if (params[:opening_candidate_id] != @assessment.opening_candidate_id)
    @opening_candidate = OpeningCandidate.find params[:opening_candidate_id]
    render 'assessments/edit'

  rescue ActiveRecord::RecordNotFound
    redirect_to candidates_url, :notice => "The object doesn't exist anymore"
  end

  # POST /opening_candidates/:opening_candidate_id/assessments
  # POST /opening_candidates.json
  def create
    @opening_candidate = OpeningCandidate.find(params[:opening_candidate_id])
    @candidate = @opening_candidate.candidate
    @opening_candidate.status = params[:opening_candidate][:status]
    @assessment = @opening_candidate.build_assessment(params[:assessment])
    respond_to do |format|
      if @assessment.save && @opening_candidate.save
        format.html { redirect_to @candidate, notice: 'Assessment was successfully made.' }
        format.json { render json: @candidate, status: :created, location: @candidate }
      else
        format.html { render action: "edit" }
        format.json { render json: @candidate.errors, status: :unprocessable_entity }
      end
    end

  #rescue ActiveRecord::RecordNotFound
  #  render "static_pages/home", :notice => "The object doesn't exist anymore"
  end

  # PUT /opening_candidates/:opening_candidate_id/assessments/:id
  # PUT /opening_candidates/:opening_candidate_id/assessments/:id.json
  def update
    Assessment.transaction do
      @assessment = Assessment.find(params[:id].to_i)

      if params[:opening_candidate_id].to_i != @assessment.opening_candidate_id.to_i
        raise ActiveRecord::RecordNotFound
      end

      @opening_candidate = OpeningCandidate.find(params[:opening_candidate_id])
      @candidate = @opening_candidate.candidate

      if @opening_candidate.status_changed_to_accepted? params[:opening_candidate][:status].to_i
        opening = Opening.find(@opening_candidate.opening_id)
        if opening.available_no > 0
          opening.increment! :filled_no
        else
          return redirect_to candidates_url, :notice => "The opening seats are all filled."
        end
      elsif @opening_candidate.status_changed_from_accepted? params[:opening_candidate][:status].to_i
        opening = Opening.find(@opening_candidate.opening_id)
        opening.decrement! :filled_no
      end

      @opening_candidate.status = params[:opening_candidate][:status].to_i
      params[:assessment][:comment] = "\r\n\r\n" + "#{current_user.email} write feedback at #{Time.now.to_date}:\r\n"  + params[:assessment][:comment]

      respond_to do |format|
        if @assessment.update_attributes(params[:assessment]) && @opening_candidate.save
          format.html { redirect_to @candidate, notice: 'Assessment was successfully updated.' }
          format.json { render json: @candidate, status: :created, location: @candidate }
        else
          format.html { render action: "edit" }
          format.json { render json: @assessment.errors, status: :unprocessable_entity }
        end
      end
    end

  rescue ActiveRecord::RecordNotFound
    redirect_to candidates_url, :notice => "The object doesn't exist anymore"
  end

end
