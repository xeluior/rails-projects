class Project < ApplicationRecord
  has_many_attached :videos
  validates :name, presence: true, uniqueness: true
end
