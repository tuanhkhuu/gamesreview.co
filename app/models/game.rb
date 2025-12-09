class Game < ApplicationRecord
  # Enums
  enum :rating_category, { everyone: 0, everyone_10_plus: 1, teen: 2, mature: 3, adults_only: 4, rating_pending: 5 }

  # Associations
  belongs_to :publisher
  belongs_to :developer
  has_many :game_platforms, dependent: :destroy
  has_many :platforms, through: :game_platforms
  has_many :game_genres, dependent: :destroy
  has_many :genres, through: :game_genres
  has_many :critic_reviews, dependent: :destroy
  has_many :user_reviews, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :metascore, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100, allow_nil: true }
  validates :user_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10, allow_nil: true }

  # Callbacks
  before_validation :generate_slug, if: -> { title.present? && slug.blank? }

  # Scopes
  scope :alphabetical, -> { order(:title) }
  scope :recent, -> { order(release_date: :desc) }
  scope :by_metascore, -> { order(metascore: :desc) }
  scope :by_user_score, -> { order(user_score: :desc) }

  private

  def generate_slug
    self.slug = title.parameterize
  end
end
