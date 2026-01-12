class Actor < ApplicationRecord
  has_many :movie_actors, dependent: :destroy
  has_many :movies, through: :movie_actors

  def self.search(query)
    if query.present?
      where('name LIKE ?', "%#{query}%")
    else
      all
    end
  end
end
