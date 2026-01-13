class LibrarySource < ApplicationRecord
  validates :path, presence: true, uniqueness: true
end
