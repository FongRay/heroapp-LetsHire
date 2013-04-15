require 'carmen'

class Opening < ActiveRecord::Base
  include Carmen

  attr_accessible :title, :description,:department_id, :status, :country, :province, :city, :total_no, :filled_no
  attr_accessible :hiring_manager_id, :recruiter_id, :participants, :participant_ids

  attr_accessible :participant_tokens
  attr_reader :participant_tokens

  belongs_to :department, :counter_cache => true
  belongs_to :hiring_manager, :class_name => "User", :foreign_key => :hiring_manager_id, :readonly => true
  belongs_to :recruiter, :class_name => "User", :foreign_key => :recruiter_id, :readonly => true
  belongs_to :creator, :class_name => "User", :foreign_key => :creator_id, :readonly => true

  has_many :opening_participants, :class_name => "OpeningParticipant", :dependent => :destroy
  has_many :participants, :class_name => "User", :through => :opening_participants

  has_many :opening_candidates, :class_name => "OpeningCandidate", :dependent => :destroy
  has_many :candidates, :class_name => "Candidate", :through => :opening_candidates

  validates :title, :presence => true

  validate :select_valid_owners_if_active,
           :total_no_should_ge_than_filled_no

  self.per_page = 20

  STATUS_LIST = { :draft => 0, :published => 1, :closed => -1 }
  scope :published, where(:status => 1)
  scope :owned_by,  ->(user_id) { where('hiring_manager_id = ? OR recruiter_id = ?', user_id, user_id) }

  def status_str
    STATUS_STRINGS[status]
  end

  def full_address
    if country.nil?
      (city || "UNKNOWN")
    else
      Country.coded(country).try { |country_obj|
        sub_regions = country_obj.subregions
        province_obj = sub_regions.respond_to?(:coded) ?  sub_regions.coded(province) : nil
        logger.debug sub_regions.inspect
        logger.debug province
        if province_obj.nil?
          (city || "UNKNOWN") + ',' + (province || "UNKNOWN") + ', ' + country_obj.name
        else
          (city || "UNKNOWN") + ',' + province_obj.name.to_s + ',' + country_obj.name
        end
      }
    end
  end

  def participant_tokens=(ids)
    self.participant_ids = ids.split(',')
  end

  def published?
    status == STATUS_LIST[:published]
  end

  def closed?
    status == STATUS_LIST[:closed]
  end

  def available_no
    total_no - filled_no
  end

  private
  def select_valid_owners_if_active
    if status != STATUS_LIST[:closed]
      if hiring_manager_id && hiring_manager_id.to_i > 0
        begin
          user = User.find(hiring_manager_id)
          valid = user && user.has_role?(:hiringmanager)
        rescue
        end
        errors.add(:hiring_manager_id, "isn't a hiring manager") unless valid
      end
      if recruiter_id && recruiter_id.to_i > 0
        valid = nil
        begin
          user = User.find(recruiter_id)
          valid = user && user.has_role?(:recruiter)
        rescue
        end
        errors.add(:recruiter_id, "isn't a recruiter") unless valid
      end
    end
  end


  def total_no_should_ge_than_filled_no
    errors.add(:filled_no, "is larger than total no.") if filled_no > total_no
  end


  STATUS_STRINGS = STATUS_LIST.invert
end
