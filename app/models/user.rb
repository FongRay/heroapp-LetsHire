class User < ActiveRecord::Base
  validates :name,  :presence => true

  # Include default devise modules. Others available are:
  # :registerable, :recoverable, :rememberable, :trackable, :validatable
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :rememberable, :validatable, :token_authenticatable

  before_save :ensure_authentication_token

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :name, :department_id, :roles, :remember_me, :deleted_at #, :authentication_token

  ROLES = %w[interviewer recruiter hiring_manager]

  self.per_page = 20

  scope :name_order, order('name ASC')
  scope :active, where(:deleted_at => nil)

  belongs_to :department
  has_many :opening_participants, :inverse_of => :participant, :dependent => :destroy
  has_many :interviewers
  has_many :interviews, :through => :interviewers

  has_many :openings, :inverse_of => :hiring_manager, :foreign_key => 'hiring_manager_id'

  def admin?
    read_attribute :admin
  end

  def self.name2role(name)
    offset = ROLES.index(name.to_s)
    offset ? 2**offset : 0
  end

  def has_role?(role_name)
    admin? || role_name.to_s == 'interviewer' || (roles_mask & User::name2role(role_name) ) != 0
  end

  def active?
    deleted_at.nil?
  end

  # The class method used in seed.rb to create the only admin user
  def self.new_admin(options = {})
    user = self.new options
    user.assign_attributes({ :admin => true }, :without_protection => true)
    user
  end

  def self.with_role(role_name)
    role_mask = name2role(role_name)
    all.select { |user|  user.admin? || (user.roles_mask & role_mask) != 0}
  end

  # The following 2 methods are defined by 'cancan', for detailed information, please
  # refer to https://github.com/ryanb/cancan/wiki/Role-Based-Authorization.
  def roles=(roles)
    self.roles_mask = ((roles & ROLES).map { |r| 2**ROLES.index(r) }.inject(0, :+)) | 1 # '| 1 ' means user always has interviewer role
  end

  def roles
    ROLES.reject do |r|
      r !=  'interviewer' && ((roles_mask || 0) & 2**ROLES.index(r)).zero?
    end
  end

  def roles_string
    roles.join(', ')
  end

  def add_role(role)
    self.roles = roles | [role]
  end

  def department_string
    Department.find(department_id).try(:name) if department_id
  end

  def active_for_authentication?
    deleted_at.nil? && super
  end

  def self.active_departments
    # Get all users which has hiring_manager's role
    department_ids = with_role(:hiring_manager).map(&:department_id).reject { |item| item.nil?}
    department_ids.try(:uniq!)
    if department_ids.try(:first)
      Department.find_all_by_id(department_ids)
    else
      []
    end
  end

  def self.include_deleted_in
    User.with_exclusive_scope { yield }
  end

end
