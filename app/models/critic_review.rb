class CriticReview < ApplicationRecord
  # Associations
  belongs_to :game
  belongs_to :publication
  belongs_to :platform, optional: true

  # Validations
  validates :score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :excerpt, length: { maximum: 500 }
  validates :review_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
  validates :game_id, uniqueness: { scope: [ :publication_id, :platform_id ], message: "already has a review from this publication for this platform" }

  # Scopes
  scope :recent, -> { order(published_at: :desc) }
  scope :by_score, -> { order(score: :desc) }
  scope :for_game, ->(game_id) { where(game_id: game_id) }
end
