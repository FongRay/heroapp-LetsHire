class InterviewsController < AuthenticatedController
  include InterviewsHelper

  def index
    authorize! :read, Interview

    mode = params[:mode]
    if mode == 'all'
     if can? :manage, Interview
     elsif can? :update, Interview
       mode = 'owned_by_me'
     else
       mode = 'interviewed_by_me'
     end
    end

    # Implement the interviews ui page filter query.
    @interviews = (case mode
                  when 'owned_by_me'
                     @default_filter = 'Any Interviews Related to Me'
                     Interview.owned_by(current_user.id).upcoming
                  when 'interviewed_by_me'
                     @default_filter = 'All of My Interviews'
                     Interview.interviewed_by(current_user.id).upcoming
                  when 'interviewed_by_me_today'
                     @default_filter = 'My Interviews Today'
                     Interview.interviewed_by(current_user.id).during(Time.zone.now)
                  when 'no_feedback'
                     @default_filter = 'Interviews without Feedback'
                     Interview.owned_by(current_user.id).where(:assessment => nil)
                  when 'all'
                     @default_filter = 'All'
                     Interview
                  else
                     @default_filter = 'Any Interviews Related to Me'
                     Interview.owned_by(current_user.id)
                  end).paginate(:page => params[:page])

    if params.has_key? :partial
      render :partial => 'interviews/interviews_index', :locals => {:opening_candidate => nil}
    end
  end

  def show
    @interview = Interview.find params[:id]
    authorize! :read, @interview
    @opening_candidate = @interview.opening_candidate
    @candidate = @interview.opening_candidate.candidate
  end

  # We allow user to update interviews in batch, user can fill up multiple interview
  # records then save them at one click.
  def edit_multiple
    authorize! :update, Interview
    @opening_candidate = OpeningCandidate.find(params[:opening_candidate_id]) unless params[:opening_candidate_id].nil?
    if @opening_candidate.nil?
      @opening = Opening.find(params[:opening_id]) unless params[:opening_id].nil?
      return redirect_to :back, :alert => 'No Candidate to schedule interviews' if @opening.nil?
      @interviews = []
    else
      @opening = @opening_candidate.opening
      @interviews = @opening_candidate.interviews
    end
  rescue ActiveRecord::RecordNotFound
    return redirect_to :back, :alert => 'Invalid Object.'
  end

  def update_multiple
    authorize! :update, Interview

    render :json => { :success => false, :messages => ['Invalid object'] } if params[:interviews].nil?
    new_interviews = params[:interviews]

    return render :json => { :success => true }  if new_interviews[:interviews_attributes].nil?
    @opening_candidate = OpeningCandidate.find new_interviews[:opening_candidate_id] unless new_interviews[:opening_candidate_id].nil?
    if @opening_candidate.nil?
      @opening_candidate = OpeningCandidate.find_by_opening_id_and_candidate_id!(new_interviews[:opening_id], new_interviews[:candidate_id])
    end
    opening = @opening_candidate.opening

    unless can? :manage, opening
      return render :json => { :success => false, :messages => ['access denied']}
    end

    new_interviews.delete :opening_candidate_id
    new_interviews.delete :opening_id
    new_interviews.delete :candidate_id
    OpeningCandidate.transaction do
      # save multiple interviews at one shot
      if @opening_candidate.update_attributes new_interviews
        user_ids = []

        # send email to notify interviewers
        candidate_name = Candidate.find(@opening_candidate.candidate_id).name
        interviews = Interview.find(:all, :conditions => ["opening_candidate_id=#{@opening_candidate.id}"])

        if interviews.any?
          interviews.each do |t|
            p "interviews:", t
            path = "http://" + request.host_with_port + "/interviews/#{t.id}"
            interviewers = Interviewer.find(:all, :conditions => ["interview_id=#{t.id}"])
            p "interviewers:", interviewers

            if interviewers.any?
              interviewers.each do |m|
                UserMailer.interview_update(User.find(m.user_id.to_i), candidate_name, path).deliver
              end
            end
          end
        end
        
        new_interviews[:interviews_attributes].each do |key, val|
          user_ids.concat val[:user_ids] if val[:user_ids].is_a?(Array)
        end

        # update database, which user should be the interviewer
        update_favorite_interviewers user_ids
        render :json => { :success => true }
      else
        render :json => { :success => false, :messages => @opening_candidate.errors.full_messages, :status => 400 }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render :json => { :success => false, :messages => ['Invalid object'] }
  end

  # Add a schedule record not save into database, partial of a page
  def schedule_add
    authorize! :create, Interview

    parse_parent
    return render :text => '' if @opening_candidate.nil? || !@opening_candidate.in_interview_loop?
    interview = Interview.new({ :modality => Interview::MODALITY_PHONE,
                                :opening_candidate_id => @opening_candidate.id,
                                :duration => 30,
                                :scheduled_at => Time.now.beginning_of_hour + 1.hour,
                                :status => Interview::STATUS_NEW})

    render :partial => 'interviews/schedule_interviews_lineitem', :locals => { :interview => interview }
  end

  # Reload all interview records, partial of a page
  def schedule_reload
    authorize! :read, Interview

    parse_parent

    return :text => '' if @opening_candidate.nil?
    @interviews = @opening_candidate.interviews

    render :partial => 'schedule_reload', :layout => false
  end

  def edit
    @interview = Interview.find params[:id]
    authorize! :update, @interview
    prepare_edit
    unless is_interviewer? @interview.interviewers
      redirect_to :back, :alert => 'Not an interviewer'
    end
  end


  def update
    @interview = Interview.find params[:id]
    authorize! :update, @interview
    unless params[:interview][:assessment].nil? || params[:interview][:assessment].length == 0
      if is_interviewer? @interview.interviewers
        @interview.assessment = params[:interview][:assessment]
      else
        return redirect_to request.referer, :alert => 'Not an interviewer'
      end
    end
    @interview.status = params[:interview][:status] unless params[:interview][:status].nil?

    if @interview.save
      redirect_to request.referer, :notice => 'Interview is updated successfully'
    else
      redirect_to request.referer
    end
  end

  # DELETE /interviews/1
  def destroy
    authorize! :manage, @interview
    @interview = Interview.find params[:id]
    interviewers = Interviewer.find(:all, :conditions => ["interview_id=#{params[:id]}"])
    @candidate = @interview.opening_candidate.candidate
    @interview.destroy

    candidate_name = @candidate.name
    path = "http://" + request.host_with_port + "/interviews"

    p "INFO:", params[:id], interviewers, candidate_name, path

    interviewers.each do |m|
      UserMailer.interview_delete(User.find(m.user_id.to_i), candidate_name, path).deliver
    end

    redirect_to (request.referrer == interview_path(@interview) ? interviews_url : :back), :notice => 'Interview was successfully deleted'
  rescue
    redirect_to interviews_url, :alert => 'Invalid interview'
  end

  private

  def update_favorite_interviewers(user_ids)
    user_ids ||= []
    if user_ids.any?
      opening = @opening_candidate.opening
      user_ids.each do |id|
        if id.to_i > 0
          op = opening.opening_participants.build
          op.user_id = id
          op.save
        end
      end
    end
  end

  def parse_parent
    @opening_candidate = OpeningCandidate.find(params[:opening_candidate_id]) unless params[:opening_candidate_id].nil?
    if @opening_candidate.nil?
      if !params[:opening_id].nil? && !params[:candidate_id].nil?
        @opening_candidate = OpeningCandidate.find_by_opening_id_and_candidate_id(params[:opening_id], params[:candidate_id])
      end
    end
  end

  def prepare_edit
    @opening_candidate = @interview.opening_candidate
    @candidate = @opening_candidate.candidate
    @opening = @opening_candidate.opening
  end

end
