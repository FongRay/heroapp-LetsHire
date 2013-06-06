class AddColumnToCandidates < ActiveRecord::Migration

  def up
    add_column :candidates, :current_opening_candidate_id, :integer, :default => -1

    Candidate.active.each do |candidate|
      opening_candidate = OpeningCandidate.where(:candidate_id => candidate.id).last
      candidate.current_opening_candidate_id = opening_candidate.id if opening_candidate
    end

  end

  def down
    remove_column :candidates, :current_opening_candidate_id
  end
end
