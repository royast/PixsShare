class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :photo
  
  def validate_comm
    if comment == "" then
      errors.add(:comment, "should not be empty")
    end
  end

  validate :validate_comm
end
