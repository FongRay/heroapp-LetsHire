require 'carmen'

class Opening < ActiveRecord::Base

  include Carmen

  attr_accessible :title, :description,:department_id, :status, :country, :province, :city, :total_no, :filled_no
  attr_accessible :hiring_manager_id, :recruiter_id, :department, :creator_id

  belongs_to :department
  belongs_to :hiring_manager, :class_name => 'User', :foreign_key => :hiring_manager_id, :readonly => true
  belongs_to :recruiter, :class_name => 'User', :foreign_key => :recruiter_id, :readonly => true
  belongs_to :creator, :class_name => 'User', :foreign_key => :creator_id, :readonly => true

  has_many :opening_participants,  :dependent => :destroy
  has_many :participants, :class_name => 'User', :through => :opening_participants

  has_many :opening_candidates,  :dependent => :destroy

  has_many :active_candidates, :class_name => 'Candidate', :foreign_key => 'current_opening_id'

  has_many :interviews, :through => :opening_candidates, :dependent => :destroy

  validates :title, :presence => true
  validates :department_id, :hiring_manager_id, :creator, :total_no, :presence => true

  validate :select_valid_owners_if_active,
           :total_no_should_ge_than_filled_no

  before_destroy :change_candidate_current_opening_candidate

  self.per_page = 20

  STATUS_LIST = { :draft => 0, :published => 1, :closed => -1 }
  scope :published, where(:status => 1)
  scope :owned_by,  ->(user_id) { where('hiring_manager_id = ? OR recruiter_id = ? OR creator_id = ?', user_id, user_id, user_id) }
  scope :created_by, ->(user_id) { where('creator_id = ?', user_id)}
  scope :interviewed_by, ->(user_id) { joins(:opening_participants => [:participant]).where('users.id = ?', user_id) }
  scope :without_candidates, lambda { where("id NOT IN (#{Candidate.joins(:opening_candidates)
                                                          .where('current_opening_id > 0')
                                                          .where('(opening_candidates.status=? OR opening_candidates.status=? OR opening_candidates.status=?)',
                                                                  OpeningCandidate::STATUS_LIST[OpeningCandidate::INTERVIEW_LOOP],
                                                                  OpeningCandidate::STATUS_LIST[OpeningCandidate::OFFER_PENDING],
                                                                  OpeningCandidate::STATUS_LIST[OpeningCandidate::OFFER_SENT])
                                                          .select('current_opening_id').uniq.to_sql})") }
  scope :without_interviewers, lambda { where("id NOT IN (#{OpeningParticipant.select('opening_id').uniq.to_sql})") }

  def status_str
    STATUS_STRINGS[status]
  end

  def full_address
    items = []
    items << city unless city.to_s.blank?
    unless country.nil?
      Country.coded(country).try do |country_obj|
        sub_regions = country_obj.subregions
        province_obj = sub_regions.respond_to?(:coded) ?  sub_regions.coded(province) : nil
        unless province_obj.nil?
          province_str = province_obj.try(:name)
        else
          province_str = province
        end
        items << province_str.to_s unless province_str.to_s.blank?
        items << country_obj.try(:name)
      end
    end
    items.join(', ')
  end


  def title_with_department
    "#{title} (Department: #{department.name})"
  end

  def published?
    status == STATUS_LIST[:published]
  end

  def closed?
    status == STATUS_LIST[:closed]
  end

  def owned_by?(user_id)
    hiring_manager_id == user_id || recruiter_id == user_id
  end

  def available_no
    total_no - filled_no
  end

  def close_operation?(new_status)
    (not closed?) and (new_status.to_i == STATUS_LIST[:closed])
  end

  private
  def select_valid_owners_if_active
    if status != STATUS_LIST[:closed]
      if hiring_manager_id && hiring_manager_id.to_i > 0
        begin
          user = User.active.find(hiring_manager_id)
          valid = user && user.has_role?(:hiring_manager)
        rescue
        end
        errors.add(:hiring_manager_id, "isn't a hiring manager") unless valid
      end
      if recruiter_id && recruiter_id.to_i > 0
        valid = nil
        begin
          user = User.active.find(recruiter_id)
          valid = user && user.has_role?(:recruiter)
        rescue
        end
        errors.add(:recruiter_id, "isn't a recruiter") unless valid
      end
    end
  end


  def total_no_should_ge_than_filled_no
    errors.add(:total_no, 'is smaller than filled seat number.') if filled_no > total_no
  end

  def change_candidate_current_opening_candidate
    opening_candidates.each do |opening_candidate|
      opening_candidate.clear_current_opening_info
    end
  end

  STATUS_STRINGS = STATUS_LIST.invert
end
