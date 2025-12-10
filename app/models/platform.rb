class Platform < ApplicationRecord
  # Enums
  enum :platform_type, { console: 0, pc: 1, mobile: 2, handheld: 3, arcade: 4 }

  # Associations
  has_many :game_platforms, dependent: :destroy
  has_many :games, through: :game_platforms
  has_many :critic_reviews, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :platform_type, presence: true

  # Callbacks
  before_validation :generate_slug, if: -> { name.present? && slug.blank? }

  # Scopes
  scope :alphabetical, -> { order(:name) }
  scope :active, -> { where(active: true) }

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
