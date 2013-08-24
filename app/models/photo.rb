class Photo < ActiveRecord::Base
  has_many :comments
  has_many :taggers
  belongs_to :user
end
