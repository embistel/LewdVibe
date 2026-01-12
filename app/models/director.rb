class Director < ApplicationRecord
  has_many :movies

  def self.search(query)
    if query.present?
      where('name LIKE ?', "%#{query}%")
    else
      all
    end
  end
end
