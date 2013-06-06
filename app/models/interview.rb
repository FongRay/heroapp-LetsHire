class Interview < ActiveRecord::Base

  belongs_to :opening_candidate
  has_many :interviewers, :dependent => :destroy
  has_many :users, :through => :interviewers
  has_many :photos, :dependent => :destroy

  attr_accessible :user_ids

  attr_accessible :opening_candidate_id
  attr_accessible :modality, :scheduled_at, :scheduled_at_iso, :duration, :phone, :location, :description
  attr_accessible :status, :score, :assessment
  attr_accessible :created_at, :updated_at

  self.per_page = 20

  # interview status constants
  STATUS_NEW      = 'scheduled'
  STATUS_PROGRESS = 'started'
  STATUS_CLOSED   = 'finished'
  STATUS_CANCELED = 'canceled'

  # interview modality constants
  MODALITY_PHONE = 'phone interview'
  MODALITY_ONSITE = 'onsite interview'

  MODALITIES = [MODALITY_PHONE, MODALITY_ONSITE]

  STATUS = [STATUS_NEW, STATUS_PROGRESS, STATUS_CLOSED, STATUS_CANCELED]

  validates :opening_candidate_id, :presence => true
  validates :modality, :scheduled_at, :presence => true
  validates :modality, :inclusion => MODALITIES
  validates :status, :inclusion => STATUS

  scope :upcoming, lambda { where('scheduled_at > ?', Time.zone.now)}
  scope :during, ->(date) { where('scheduled_at >= ? and scheduled_at <= ?', date.to_time.at_beginning_of_day, date.end_of_day)}
  scope :interviewed_by, ->(user_id) { joins(:interviewers).where('interviewers.user_id = ? ', user_id)}
  scope :owned_by, ->(user_id) { includes(:opening_candidate => [:opening]).where('openings.hiring_manager_id = ? OR openings.recruiter_id = ? OR openings.creator_id = ?', user_id, user_id, user_id) }

  def cancel_interview(reason)
    update_attributes({:status => STATUS_CANCELED, :assessment=> reason})
  end

  def scheduled_at_iso
    if scheduled_at
      scheduled_at.iso8601
    else
      nil
    end
  end

  def scheduled_at_iso=(val)
    self.scheduled_at = Time.parse val
  rescue
  end

  def interviewers_str
    default_department_id = opening_candidate.opening.department_id
    users.collect do |user|
      user.department_id == default_department_id ? user.name : "#{user.name}(#{user.department.name})"
    end
  end

  def phone_interview?
    modality == MODALITY_PHONE
  end

  def editable?
    status != STATUS_CLOSED
  end

  def finished?
    status == STATUS_CLOSED
  end

  def canceled?
    status == STATUS_CANCELED
  end

end
