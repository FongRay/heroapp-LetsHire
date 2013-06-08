require 'spec_helper'

describe UsersController do
  def valid_attributes
    FactoryGirl.attributes_for(:user)
  end

  before :each do
    request.env['devise.mapping'] = Devise.mappings[:user]
    sign_in_as_admin
  end

  describe 'GET index' do
    xit 'assigns all users as @users' do
      #Don't work for pagination
      user = User.create! valid_attributes
      get :index, {}
      assigns(:users).should eq( User.all | [user])
    end
  end

  describe 'GET show' do
    it 'assigns the requested user as @user' do
      user = User.create! valid_attributes
      get :show, {:id => user.to_param}
      assigns(:user).should eq(user)
    end
  end

  describe 'GET new' do
    it 'assigns new user as @user' do
      get :new, {}
      assigns(:user).should be_a_new(User)
    end
  end

  describe 'GET edit' do
    it 'assigns the requested user as @user' do
      user = User.create! valid_attributes
      get :edit, {:id => user.to_param}
      assigns(:user).should eq(user)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new User" do
        expect {
          post :create, {:user => valid_attributes}
        }.to change(User, :count).by(1)
      end

      it "assigns a newly created user as @user" do
        post :create, {:user => valid_attributes}
        assigns(:user).should be_a(User)
        assigns(:user).should be_persisted
      end

      it "redirects to the users list" do
        post :create, {:user => valid_attributes}
        response.should redirect_to(users_url)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved user as @user" do
        # Trigger the behavior that occurs when invalid params are submitted
        User.any_instance.stub(:save).and_return(false)
        post :create, {:user => {}}
        assigns(:user).should be_a_new(User)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        User.any_instance.stub(:save).and_return(false)
        post :create, {:user => {}}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested user" do
        user = User.create! valid_attributes
        # Assuming there are no other users in the database, this
        # specifies that the User created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        User.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => user.to_param, :user => {'these' => 'params'}}
      end

      it "assigns the requested user as @user" do
        user = User.create! valid_attributes
        put :update, {:id => user.to_param, :user => valid_attributes}
        assigns(:user).should eq(user)
      end

      it "redirects to the user" do
        user = User.create! valid_attributes
        put :update, {:id => user.to_param, :user => valid_attributes}
        response.should redirect_to(user)
      end
    end

    describe "with invalid params" do
      it "assigns the user as @user" do
        user = User.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        User.any_instance.stub(:save).and_return(false)
        put :update, {:id => user.to_param, :user => {}}
        assigns(:user).should eq(user)
      end

      it "re-renders the 'edit' template" do
        user = User.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        User.any_instance.stub(:save).and_return(false)
        put :update, {:id => user.to_param, :user => {}}
        response.should render_template("edit")
      end
    end
  end

  describe "User Reactivate/Deactivate" do

    before :each do
      request.env['HTTP_REFERER'] = users_url
    end

    it "deactivate a user" do
      user = User.create! valid_attributes
      put :deactivate, {:id => user.to_param}
      expect(response).to redirect_to(users_url)
      expect(flash[:alert]).to eq(nil)

      expect(assigns(:user).deleted_at).to_not eq(nil)

    end

    it "reactivate a user" do
      user = User.create! valid_attributes.merge(:deleted_at => Time.current)
      put :reactivate, {:id => user.to_param}
      response.should redirect_to(users_url)
      flash[:alert].should eq(nil)

      assigns(:user).deleted_at.should eq(nil)

    end

    it "cannot deactivate yourself" do
      put :deactivate, { :id => subject.current_user.to_param}
      flash[:alert].should eq('Cannot disable yourself')
    end

    describe "Busy User Deactivate" do

      before :each do
        @users = []
        [:hiring_manager, :recruiter].each { |role| @users << create_user(role) }
        @opening = Opening.create! FactoryGirl.attributes_for(:opening).merge({:hiring_manager_id => @users[0].id,
                                                                              :department_id => @users[0].department_id,
                                                                              :recruiter_id => @users[1].id,
                                                                              :creator_id => @users[1].id,
                                                                              :status => 1})

      end

      it "cannot deactivate an active hiring_manager" do
        put :deactivate, { :id => @users[0].to_param}
        flash[:alert].should include('active openings')
        user = @users[0]
        user.reload
        user.deleted_at.should eq(nil)

      end

      it "cannot deactivate an active recruiter" do
        put :deactivate, { :id => @users[1].to_param}
        flash[:alert].should include('active openings')
        user = @users[1]
        user.reload
        user.deleted_at.should eq(nil)

      end


      it "cannot deactivate an active interviewer" do
        interviewers = []
        [:interviewer, :interviewer].each { |role| interviewers << create_user(role) }
        candidate = Candidate.create! FactoryGirl.attributes_for(:candidate)
        opening_candidate = candidate.opening_candidates.create! :opening_id => @opening.to_param
        Interview.create! FactoryGirl.attributes_for(:interview).merge({
                                                     :status => Interview::STATUS_CLOSED,
                                                     :opening_candidate_id => opening_candidate.id,
                                                     :user_ids => [interviewers[0].id]})
        put :deactivate, { :id => interviewers[0].to_param}
        flash[:alert].should eq(nil)
        user = interviewers[0]
        user.reload
        expect(user.deleted_at).not_to eq(nil)

        Interview.create! FactoryGirl.attributes_for(:interview).merge({
                                                     :opening_candidate_id => opening_candidate.id,
                                                     :user_ids => [interviewers[1].id]})
        put :deactivate, { :id => interviewers[1].to_param}
        flash[:alert].should include('active interviews')
        user = interviewers[1]
        user.reload
        user.deleted_at.should eq(nil)

      end

      it "should not contain deactivated user in list for user selection" do
        pending "will refactor UserController.index_for_tokens later and add test cases here"
      end
    end

  end

end
