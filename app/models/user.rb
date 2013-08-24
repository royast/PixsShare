class User < ActiveRecord::Base
  has_many :comments
  has_many :photos
  has_many :friends
  has_many :taggers
  def validate_usr
    if( User.find_by_login(login)) then
      errors.add(:user, "login ID is taken, please choose a new login ID")
    end
  end

  validate :validate_usr
  
end
