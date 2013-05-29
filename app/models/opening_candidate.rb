class OpeningCandidate < ActiveRecord::Base
  attr_accessible :candidate_id, :opening_id, :status, :interviews_attributes

  belongs_to :candidate, :counter_cache => true
  belongs_to :opening, :counter_cache => true

  has_many :interviews, :dependent => :destroy

  has_one :assessment, :dependent => :destroy

  validates :candidate_id, :opening_id, :presence => true

  validates :candidate_id, :uniqueness => { :scope => :opening_id }

  accepts_nested_attributes_for :interviews, :allow_destroy => true, :reject_if => proc { |interview| interview.empty? }

  # find all 'rejected' records belong to recruiter user
  scope :rejected, ->(user_id) { where( :status => STATUS_LIST['Offer Declined']).joins(:opening).where(['openings.recruiter_id = ?', user_id]) }
  scope :notconfirmed, ->(user_id) { where( :status => STATUS_LIST['Offer Pending']).joins(:opening).where(['openings.recruiter_id = ?', user_id]) }
  scope :accepted, ->(user_id) { OpeningCandidate.where( :status => STATUS_LIST['Offer Accepted']).joins(:opening).where(['openings.recruiter_id = ?', user_id]) }

  def status_str
    status.nil? ? INTERVIEW_LOOP : STATUS_STRINGS[status]
  end

  def next_status_options
    STATUS_LIST
  end

  def candidate_name
    candidate.try(:name)
  end

  def all_interviews_finished?
    return false if interviews.empty?
    interviews.each do |interview|
      return false unless interview.finished?
    end
    true
  end

  def in_interview_loop?
    status == OpeningCandidate::STATUS_LIST[OpeningCandidate::INTERVIEW_LOOP]
  end

  def quit?
    status == OpeningCandidate::STATUS_LIST[OpeningCandidate::QUIT]
  end

  def closed?
    status == OpeningCandidate::STATUS_LIST[OpeningCandidate::CLOSED]
  end

  def fail_job_application(reason='')
    update_attributes(:status => OpeningCandidate::STATUS_LIST[OpeningCandidate::FAIL], :assessment => reason)
  end

  def quit_job_application
    update_attributes(:status => OpeningCandidate::STATUS_LIST[OpeningCandidate::QUIT])
  end

  def close_job_application
    update_attributes(:status => OpeningCandidate::STATUS_LIST[OpeningCandidate::CLOSED])
  end

  def reopen_job_application
    update_attributes(:status => OpeningCandidate::STATUS_LIST[OpeningCandidate::LOOP])
  end

  # find all 'rejected' records belong to recruiter user

  INTERVIEW_LOOP = 'Interview Loop'
  FAIL = 'Fail'
  QUIT = 'Quit'
  CLOSED = 'Closed'
  OFFER_ACCEPTED = 'Offer Accepted'
  #Don't change order randomly. order matters.
  STATUS_LIST = { INTERVIEW_LOOP => 1,
                  FAIL => 2,
                  QUIT => 3,   # candidate quit
                  CLOSED => 4, # opening closed
                  'Offer Pending' => 7,
                  'Offer Sent' => 8,
                  'Offer Declined' => 9,
                  OFFER_ACCEPTED => 10}
  STATUS_STRINGS = STATUS_LIST.invert

end
