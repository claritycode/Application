# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  email                  :string(255)
#  username               :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  password_digest        :string(255)
#  remember_token         :string(255)
#  admin                  :boolean          default(FALSE)
#  password_reset_token   :string(255)
#  password_reset_sent_at :datetime
#

class User < ActiveRecord::Base
  attr_accessible :email, :name, :username, :password, :password_confirmation
  attr_accessor :updating_password
  has_many :microposts, dependent: :destroy #destroyes the dependent microposts
  has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  has_many :followed_users, through: :relationships, source: :followed
  has_many :reverse_relationships, foreign_key: "followed_id", 
             class_name: "Relationship", dependent: :destroy

  has_many :followers, through: :reverse_relationships
  has_secure_password

  before_save { |user| user.email = email.downcase }
  # before_save :create_remember_token
  before_save { generate_token(:remember_token) }

  validates :name, presence: true, length: { maximum: 50 }
  
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX },
  				uniqueness: { case_sensitive: false }

  #...................Additional Username.............................
  VALID_USERNAME_REGEX = /\A\w+\z/i  #Only letters, numbers & underscore
  validates :username, presence: true, format: { with: VALID_USERNAME_REGEX },
  				uniqueness: { case_sensitive: false }

  validates :password, length: { minimum: 6 }, if: :should_validate_password?
  validates :password_confirmation, presence: true, if: :should_validate_password?


  def feed
    Micropost.from_users_followed_by(self)
  end

  def following?(other_user)
    relationships.find_by_followed_id(other_user.id)
  end

  def follow!(other_user)
    relationships.create!(followed_id: other_user.id)
  end

  def unfollow!(other_user)
    relationships.find_by_followed_id(other_user.id).destroy
  end

  def send_password_reset_email
    generate_token(:password_reset_token)
    self.password_reset_sent_at = Time.zone.now
    save!
    UserMailer.password_reset(self).deliver
  end

  private

    def generate_token(column)
      # self.column = SecureRandom.urlsafe_base64    
      self[column] = SecureRandom.urlsafe_base64   
    end
    
    # def create_remember_token
    #       self.remember_token = SecureRandom.urlsafe_base64
    # end

    def should_validate_password?
      updating_password || new_record?
    end
end
