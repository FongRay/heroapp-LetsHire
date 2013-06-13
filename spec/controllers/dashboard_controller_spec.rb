require 'spec_helper'

describe DashboardController do

  def valid_opening(hiring_manager, recruiter, creator)
    {
      :title => 'Marketing Manager',
      :department_id => 1,
      :hiring_manager_id => hiring_manager.id,
      :recruiter_id => recruiter.id,
      :status => 1,
      :creator_id => creator.id
    }
  end

  def valid_candidate
    {
      :name  => Faker::Name.name,
      :email => Faker::Internet.email,
      :phone => Faker::PhoneNumber.phone_number,
      :source => Faker::Lorem.word,
      :description => Faker::Lorem.sentence
    }
  end

  def valid_opening_candidate(opening, candidate)
    {
        :opening_id => opening.id,
        :candidate_id => candidate.id,
    }
  end

  def valid_interview(opening_candidate)
    {
        :opening_candidate_id => opening_candidate.id,
        :scheduled_at => (Time.zone.now + 1.day),
        :modality => 'onsite interview'
    }
  end

  def valid_assessment(opening_candidate, creator)
    {
        :opening_candidate_id => opening_candidate.id,
        :comment => 'Not too bad'
    }
  end

  def create_user(role)
    attrs = FactoryGirl.attributes_for(role)
    attrs.delete(:admin)
    User.create! attrs
  end

  def create_opening(hiring_manager, recruiter, creator)
    Opening.create! valid_opening(hiring_manager, recruiter, creator)
  end

  def create_opening_candidate(opening, candidate)
    opening_candidate = OpeningCandidate.create! valid_opening_candidate(opening, candidate)
    candidate.current_opening_id = opening.id
    candidate.current_opening_candidate_id = opening_candidate.id
    candidate.save!
    opening_candidate
  end

  def assign_opening_to_candidate(opening, candidate)
    opening_candidate = OpeningCandidate.create! valid_opening_candidate(opening, candidate)
    candidate.current_opening_id = opening.id
    candidate.current_opening_candidate_id = opening_candidate.id
    candidate.save!
    opening_candidate
  end

  def schedule_opening_interview_to_candidate(candidate, opening)
    opening_candidate = create_opening_candidate(opening, candidate)
    Interview.create! valid_interview(opening_candidate)
  end

  def assign_interview_to_user(interview, user)
    interview.user_ids = [user.id]
  end

  before :each  do
    request.env['devise.mapping'] = Devise.mappings[:user]
    @user = sign_in_as_admin
    @hiring_manager = create_user(:hiring_manager)
    @recruiter = create_user(:recruiter)
    @candidate = Candidate.create! valid_candidate
    @opening = create_opening(@hiring_manager, @recruiter, @hiring_manager)
  end

  describe "GET 'overview'" do
    it 'returns http success' do
      get 'overview'
      response.should be_success
    end

    it 'assign active openings to @active_openings' do
      sign_in @hiring_manager
      get 'overview'
      assigns(:active_openings).should include(@opening)
      @opening.status = -1
      @opening.save!
      get 'overview'
      assigns(:active_openings).should_not include(@opening)
    end

    it 'assign openings without candidate to @openings_without_candidate' do
      sign_in @hiring_manager
      get 'overview'
      assigns(:openings_without_candidate).should include(@opening)
      assign_opening_to_candidate @opening, @candidate
      get 'overview'
      assigns(:openings_without_candidate).should_not include(@opening)
    end

    it 'assign candidate without opening to @candidates_without_opening' do
      sign_in @recruiter
      get 'overview'
      assigns(:candidates_without_opening).should include(@candidate)
      assign_opening_to_candidate @opening, @candidate
      get 'overview'
      assigns(:candidates_without_opening).should_not include(@candidate)
    end

    it 'assign candidate without interview to @candidates_without_interview' do
      opening_candidate = assign_opening_to_candidate @opening, @candidate
      Candidate.in_interview_loop.should include @candidate
      Candidate.no_interviews.should include @candidate
      sign_in @recruiter
      get 'overview'
      assigns(:candidates_without_interview).should include(@candidate)
      Interview.create! valid_interview(opening_candidate)
      get 'overview'
      assigns(:candidates_without_interview).should_not include(@candidate)
    end


    it '@candidates_w/o_assessment should has interview as prerequisite and take assessment as input' do
      sign_in @recruiter
      opening_candidate = create_opening_candidate(@opening, @candidate)

      interview = Interview.create! valid_interview(opening_candidate)
      Candidate.with_interview.should include(@candidate)
      Candidate.with_feedback.should_not include(@candidate)
      get 'overview'
      assigns(:candidates_with_assessment).should_not include(@candidate)
      assigns(:candidates_without_assessment).should_not include(@candidate)

      interview.assessment = 'pass'
      interview.save!
      Candidate.with_feedback.should include(@candidate)
      get 'overview'
      assigns(:candidates_with_assessment).should_not include(@candidate)
      assigns(:candidates_without_assessment).should include(@candidate)

      Assessment.create! valid_assessment(opening_candidate, @hiring_manager)
      get 'overview'
      assigns(:candidates_with_assessment).should include(@candidate)
      assigns(:candidates_without_assessment).should_not include(@candidate)
    end



    it 'assign upcoming interviews owned by me to @interviews_owned_by_me' do
      sign_in @recruiter
      get 'overview'
      assigns(:interviews_owned_by_me).size.should be 0
      interview = schedule_opening_interview_to_candidate @candidate, @opening
      assign_interview_to_user(interview, @recruiter)
      get 'overview'
      assigns(:interviews_owned_by_me).should include(interview)
    end

    it 'assign upcoming interviews interviewed by me to @interviews_interviewed_by_me' do
      sign_in @recruiter
      get 'overview'
      assigns(:interviews_interviewed_by_me).size.should be 0
      interview = schedule_opening_interview_to_candidate @candidate, @opening
      assign_interview_to_user(interview, @recruiter)
      get 'overview'
      assigns(:interviews_interviewed_by_me).should include(interview)
    end
  end
end
