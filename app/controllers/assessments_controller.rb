class AssessmentsController < ApplicationController
  before_filter { authorize! :manage, Candidate }
  def new
    @opening_candidate = OpeningCandidate.find params[:opening_candidate_id]
    if @opening_candidate
      @assessment = Assessment.new(:opening_candidate_id => @opening_candidate.id)
      render 'assessments/edit'
    else
      redirect_to candidates_url, :alert => "The parent doesn't exist anymore"
    end
  end


  # GET /opening_candidates/:opening_candidate_id/assessments/:id/edit
  def edit
    @assessment = Assessment.find(params[:id])

    raise ActiveRecord::RecordNotFound if (params[:opening_candidate_id] != @assessment.opening_candidate_id)
    @opening_candidate = OpeningCandidate.find params[:opening_candidate_id]
    render 'assessments/edit'

  rescue ActiveRecord::RecordNotFound
    redirect_to candidates_url, :alert => "The object doesn't exist anymore"
  end

  # POST /opening_candidates/:opening_candidate_id/assessments
  def create
    @opening_candidate = OpeningCandidate.find(params[:opening_candidate_id])
    @candidate = @opening_candidate.candidate
    @opening_candidate.status = params[:opening_candidate][:status]
    @assessment = @opening_candidate.build_assessment(params[:assessment])
    if @assessment.save && @opening_candidate.save
      redirect_to @candidate, notice: 'Assessment was successfully made.'
    else
      render action: "edit"
    end

  rescue ActiveRecord::RecordNotFound
    redirect_to candidates_url, :alert => "The object doesn't exist anymore"
  end

  # PUT /opening_candidates/:opening_candidate_id/assessments/:id
  def update
    unless (params.has_key?(:opening_candidate) && params.has_key?(:assessment))
      return redirect_to candidates_url, :alert => 'Invalid param'
    end

    @assessment = Assessment.find(params[:id].to_i)

    new_status = params[:opening_candidate][:status].to_i
    if params[:opening_candidate_id].to_i != @assessment.opening_candidate_id
      redirect_to candidates_url, :alert => "Invalid object!"
    end

    @opening_candidate = @assessment.opening_candidate
    @candidate = @opening_candidate.candidate

    Assessment.transaction do
      if @opening_candidate.status_changed_to_accepted? new_status
        if @opening_candidate.opening.available_no == 0
          return redirect_to request.referer, :alert => "Fail to mark candidate as 'Offer Accepted' because the opening's seats are all filled."
        end
        @opening_candidate.opening.increment! :filled_no
      elsif @opening_candidate.status_changed_from_accepted? new_status
        @opening_candidate.decrement! :filled_no
      end

      @opening_candidate.status = new_status
      params[:assessment][:comment] = "\r\n\r\n" + "#{current_user.email} write feedback at #{Time.now.to_date}:\r\n"  + params[:assessment][:comment]

      if @assessment.update_attributes(params[:assessment]) && @opening_candidate.save
        redirect_to @candidate, :notice => 'Assessment was successfully updated.'
      else
        render action: "edit"
      end
    end

  rescue ActiveRecord::RecordNotFound
    redirect_to candidates_url, :alert => "The object doesn't exist anymore"
  end

end
