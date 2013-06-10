class Candidate < ActiveRecord::Base
  attr_accessible :name, :email, :phone, :source, :description, :status, :current_opening_candidate_id, :current_opening_id

  # candidate status constants
  NORMAL = 0
  INACTIVE = 1

  STATUS_DESC = {
      NORMAL   => 'normal',
      INACTIVE => 'in blacklist'
  }

  # valid phone number examples
  # 754-647-0105 x6950
  # (498)479-4559 x2262
  # 775.039.9227 x42375
  # 1-220-680-6355 x59164
  phone_format = Regexp.new("^(\\(\\d+\\)){0,1}(\\d+)[\\d|\\.|-]*(\\sx\\d+){0,1}$")

  validates :name, :presence => true
  validates :email,:presence => true
  validates :email, :email_format => { :message => 'format error' }, :if => :email?
  validates :phone, :presence => true
  validates :phone, :format => { :with => phone_format, :message => 'format error' }, :if => :phone?

  self.per_page = 20

  has_many :opening_candidates, :class_name => 'OpeningCandidate', :dependent => :destroy
  has_one  :resume, :class_name => 'Resume', :dependent => :destroy

  belongs_to :active_opening, :class_name => 'Opening', :foreign_key => 'current_opening_id'

  scope :active, where(:status => NORMAL)
  scope :inactive, where(:status => INACTIVE)

  scope :no_openings, where('current_opening_candidate_id<1')
  scope :with_opening, where('current_opening_candidate_id>0')
  scope :in_interview_loop, joins(:opening_candidates).where('current_opening_candidate_id=opening_candidates.id AND opening_candidates.status=1')

  scope :not_in_opening, ->(opening_id) { where("id NOT IN (SELECT DISTINCT candidate_id FROM opening_candidates WHERE opening_id=#{opening_id})") }


  scope :with_interview_sql, where('current_opening_candidate_id IN (
                               SELECT "opening_candidates"."id" FROM "opening_candidates"
                               INNER JOIN "interviews" ON "interviews"."opening_candidate_id" = "opening_candidates"."id")')
  scope :with_interview, lambda { where(:current_opening_candidate_id => OpeningCandidate.in_interview_loop.joins(:interviews).pluck("opening_candidates.id").uniq) }
  scope :with_feedback, lambda { where(:current_opening_candidate_id => OpeningCandidate.in_interview_loop.joins(:interviews).where("interviews.assessment IS NOT NULL").pluck("opening_candidates.id").uniq) }

  #scope :no_interviews, lambda { where('candidates.id NOT in (
  #                            SELECT DISTINCT "candidates"."id" FROM "candidates"
  #                            INNER JOIN "opening_candidates" ON "opening_candidates"."candidate_id" = "candidates"."id"
  #                            INNER JOIN "interviews" ON "interviews"."opening_candidate_id" = "opening_candidates"."id" )
  #                            AND current_opening_candidate_id > 0').in_interview_loop }
  scope :no_interviews, lambda { in_interview_loop.where('current_opening_candidate_id NOT IN (?)', OpeningCandidate.joins(:interviews).uniq.pluck(:opening_candidate_id).push(0)) }

  scope :with_assessment_sql, where('current_opening_candidate_id IN (
                                SELECT "opening_candidates"."id" FROM "opening_candidates"
                                INNER JOIN "assessments" ON "assessments"."opening_candidate_id" = "opening_candidates"."id"
                                WHERE "assessments"."comment" IS NOT NULL)')
  scope :with_assessment, lambda{ where(:current_opening_candidate_id => OpeningCandidate.joins(:assessment).where('"assessments"."comment" IS NOT NULL')) }

  #scope :without_assessment_sql, where('current_opening_candidate_id NOT IN (
  #                                 SELECT "opening_candidates"."id" FROM "opening_candidates"
  #                                 INNER JOIN "assessments" ON "assessments"."opening_candidate_id" = "opening_candidates"."id"
  #                                 WHERE "assessments"."comment" IS NOT NULL)
  #                                 AND current_opening_candidate_id > 0')
  scope :without_assessment, lambda { with_feedback.where("current_opening_candidate_id NOT IN (?)",
                                   OpeningCandidate.joins(:assessment).where('"assessments"."comment" IS NOT NULL')
                                   .pluck(:opening_candidate_id).uniq.push(0)) }

  def opening(index)
    opening_candidates[index].opening if opening_candidates.size > index
  end

  def interviews_finished_no_assess?
    opening_candidates = OpeningCandidate.where(:candidate_id => id)
    opening_candidates.each do |opening_candidate|
      if opening_candidate.all_interviews_finished?
        assessments = Assessment.where(:opening_candidate_id => opening_candidate.id)
        return true if assessments.empty?
      end
    end
    false
  end

  def mark_inactive(reason = '')
    # mark all unfinished interviews to be 'canceled' status
    # mark all opening_candidates during interviewing to be 'quit' status
    OpeningCandidate.transaction do
      Interview.transaction do
        opening_candidates.each do |opening_candidate|
          opening_candidate.interviews.each do |interview|
            unless interview.finished?
              interview.cancel_interview(reason)
            end
          end
          opening_candidate.fail_job_application('moved to blacklist: ' + reason) if opening_candidate.in_interview_loop?
        end
      end
    end
    update_attributes(:status => INACTIVE)
  end

  def mark_active
    opening_candidates.each do |opening_candidate|
      # NOTE: For these 'canceled' interviews we do not touch them user should
      # schedule new round of interviews.
      opening_candidate.reopen_job_application if opening_candidate.quit?
    end
    update_attributes(:status => NORMAL)
  end

  def status_str
    STATUS_DESC[status]
  end

  def active_opening_candidate
    OpeningCandidate.find_by_id current_opening_candidate_id
  end

  def overall_status_str
    inactive? ? 'Inactive' : (current_opening_candidate_id > 0 ? active_opening_candidate.status_str : 'No job assigned')
  end

  def inactive?
    # NOTE: Shall we keep another table to store candidates in blacklist?
    status == INACTIVE # means the candidate is in blacklist
  end

  def self.status_description
    description = []
    STATUS_DESC.each do |key, value|
      description << [value, key]
    end
    description
  end

  def self.no_assessment
    candidates = Candidate.with_interview.select! do |candidate|
      candidate.interviews_finished_no_assess?
    end
    candidates || []
  end

end
