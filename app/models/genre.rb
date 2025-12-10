class Genre < ApplicationRecord
  # Associations
  has_many :game_genres, dependent: :destroy
  has_many :games, through: :game_genres

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }

  # Callbacks
  before_validation :generate_slug, if: -> { name.present? && slug.blank? }

  # Scopes
  scope :alphabetical, -> { order(:name) }

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
