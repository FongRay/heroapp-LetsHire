require 'spec_helper'

describe CandidatesController do

  def valid_candidate
    FactoryGirl.attributes_for(:candidate)
  end

  before :all do
    @hiring_manager1 = create_user(:hiring_manager)
    @recruiter1 = create_user(:recruiter)

    @users = []
    3.times { @users << create_user(:user) }

    Opening.delete_all
    Candidate.delete_all
    OpeningCandidate.delete_all
    Interview.delete_all

    @opening = Opening.create! FactoryGirl.attributes_for(:opening).merge(:creator_id => @users[0].id,
                                                                          :hiring_manager_id => @hiring_manager1.id,
                                                                          :department_id => @hiring_manager1.department_id)
    @candidate = Candidate.create! FactoryGirl.attributes_for(:candidate)
    @candidate.should be_valid
  end

  before :each  do
    request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in_as_admin
  end

  describe "GET index" do
    it "assigns all candidates as @candidates" do
      candidate = Candidate.create! valid_candidate
      Candidate.stub(:paginate).and_return([candidate])
      get :index, {}
      assigns(:candidates).should include(@candidate) # by default we only get active candidates
    end

    it "assigns candidates under filter condition as @candidates" do
      candidate = Candidate.create! FactoryGirl.attributes_for(:candidate)
      candidate.should be_valid
      opening_candidate = OpeningCandidate.create!(:opening_id => @opening.id, :candidate_id => candidate.id)
      opening_candidate.should be_valid
      get :index, {:mode => 'all' }
      assigns(:candidates).should include(candidate)
      assigns(:candidates).should include(@candidate)
    end
  end

  describe "Create job_opening & GET show" do
    it "should see correct user details" do
      request.env['HTTP_REFERER'] = candidates_url
      put :create_opening, { :id => @candidate.id, :candidate => {:opening_id => @opening.id }}
      @opening_candidate = OpeningCandidate.find_by_candidate_id_and_opening_id(@candidate.id, @opening.id)
      @opening_candidate.should be_valid
      @candidate.reload
      @opening_candidate.id.should eq(@candidate.current_opening_candidate_id)
      @interview = Interview.create! FactoryGirl.attributes_for(:interview).merge(:opening_candidate_id => @opening_candidate.id)
      @interview.should be_valid

      get :show, { :id => @candidate.to_param}
      assigns(:candidate).should eq(@candidate)
      assigns(:latest_applying_job).should eq(@opening_candidate)
      assigns(:opening).should eq(@opening)
      assigns(:interviews).should eq([@interview])
    end
  end

  describe "GET new" do
    it "assigns a new candidate as @candidate" do
      get :new, {}
      assigns(:candidate).should be_a_new(Candidate)
    end
  end

  describe "GET edit" do
    it "assigns the requested candidate as @candidate" do
      candidate = Candidate.create! valid_candidate
      get :edit, { :id => candidate.to_param }
      assigns(:candidate).should eq(candidate)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Candidate" do
        expect do
          post :create, { :candidate => valid_candidate }
        end.to change(Candidate, :count).by(1)
      end

      it "assigns a newly created candidate as @candidate" do
        post :create, { :candidate => valid_candidate }
        assigns(:candidate).should be_a(Candidate)
        assigns(:candidate).should be_persisted
      end

    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved candidate as @candidate" do
        Candidate.any_instance.stub(:save).and_return(false)
        post :create, { :candidate => valid_candidate.merge(:email => nil) }
        assigns(:candidate).should be_a_new(Candidate)
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested candidate" do
        candidate = Candidate.create! valid_candidate
        Candidate.any_instance.should_receive(:update_attributes).with({ 'these' => 'params' })
        put :update, { :id => candidate.to_param, :candidate => { 'these' => 'params' } }
      end

      it "assigns the requested candidate as @candidate" do
        candidate = Candidate.create! valid_candidate
        put :update, { :id => candidate.to_param, :candidate => valid_candidate }
        assigns(:candidate).should eq(candidate)
      end
    end

    describe "with invalid params" do
      it "assigns the candidate as @candidate" do
        candidate = Candidate.create! valid_candidate
        Candidate.any_instance.stub(:save).and_return(false)
        put :update, { :id => candidate.to_param, :candidate => {} }
        assigns(:candidate).should eq(candidate)
      end

      it "re-renders the edit template" do
        candidate = Candidate.create! valid_candidate
        Candidate.any_instance.stub(:save).and_return(false)
        put :update, { :id => candidate.to_param, :candidate => {} }
        response.should render_template("edit")
      end
    end
  end

end
