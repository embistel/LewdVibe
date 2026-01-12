

class Movie < ApplicationRecord
  belongs_to :studio, optional: true
  belongs_to :director, optional: true
  has_many :movie_actors, dependent: :destroy
  has_many :actors, through: :movie_actors

  def self.search(query)
    if query.present?
      where('title LIKE ?', "%#{query}%")
    else
      all
    end
  end
end
