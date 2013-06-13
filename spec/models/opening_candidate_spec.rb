require 'spec_helper'

describe OpeningCandidate do

  it "requires unique_indexes to be present" do
    FactoryGirl.build(:opening_candidate, :candidate_id => nil).should_not be_valid
    FactoryGirl.build(:opening_candidate, :opening_id => nil).should_not be_valid

    begin
      FactoryGirl.create(:opening_candidate)
      FactoryGirl.build(:opening_candidate).should_not be_valid
    rescue
    end
  end
end
