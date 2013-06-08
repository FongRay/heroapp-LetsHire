class DashboardController < ApplicationController
  before_filter :require_login

  def overview
    # interviews related action items data providers

    if can? :manage, Opening
      @active_openings = Opening.published.owned_by(current_user.id)
      @openings_without_candidate = Opening.published.without_candidates.owned_by(current_user.id)
    end

    if can? :manage, Candidate
      @candidates_without_opening = Candidate.active.no_openings
      @candidates_without_interview = Candidate.active.no_interviews
      #Fixme: no_assessment isn't a scope, cannot apply scope 'active' for without_assessment
      @candidates_without_assessment = Candidate.active.without_assessment
      @candidates_with_assessment = Candidate.active.with_assessment
    end

    @interviews_interviewed_by_me = Interview.interviewed_by(current_user.id).upcoming
    if can? :manage, Interview
      @interviews_owned_by_me = Interview.owned_by(current_user.id).upcoming
      @interviews_without_feedback = Interview.where(:assessment => nil)
    else
      @interviews_without_feedback = current_user.interviews.where(:assessment => nil)
    end

    # opening related action items data providers
    @active_openings ||= []
    @openings_without_candidate ||= []

    # candidates related action items data providers
    @candidates_without_opening ||= []
    @candidates_without_interview ||= []
    @candidates_without_assessment ||= []
    @candidates_with_assessment ||= []


    @interviews_owned_by_me ||= []
    @interviews_interviewed_by_me ||= []
    @interviews_without_feedback ||= []


    # data displayed in charts
    @openings_created_by_me = Opening.created_by(current_user.id).length
    @openings_assigned_to_me = Opening.owned_by(current_user.id).length
    @openings_without_interviewers = Opening.published.without_interviewers.length

    # FIXME: Do we arrange interview on Sunday and Saturday ?
    @dates = []
    @interviews_assigned_to_me = []
    @interviews_upcoming_today = []
    (0..6).reverse_each do |i|
      date = (Time.now - i.days).to_date
      @dates << "#{date.month}-#{date.day}"
      @interviews_assigned_to_me << Interview.owned_by(current_user.id).during(date).length
      @interviews_upcoming_today << Interview.interviewed_by(current_user.id).during(date).length
    end

    @offers_rejected = OpeningCandidate.rejected(current_user.id).count
    @offers_notconfirmed = OpeningCandidate.notconfirmed(current_user.id).count
    @offers_accepted = OpeningCandidate.accepted(current_user.id).count

  end
end
