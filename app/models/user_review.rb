class UserReview < ApplicationRecord
  # Enums
  enum :completion_status, { not_played: 0, playing: 1, completed: 2, abandoned: 3 }
  enum :difficulty_rating, { very_easy: 0, easy: 1, medium: 2, hard: 3, very_hard: 4 }
  enum :moderation_status, { pending: 0, approved: 1, flagged: 2, rejected: 3 }

  # Associations
  belongs_to :user
  belongs_to :game
  belongs_to :platform, optional: true

  # Validations
  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :body, presence: true, length: { minimum: 50, maximum: 5000 }
  validates :score, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }
  validates :hours_played, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validates :user_id, uniqueness: { scope: [ :game_id, :platform_id ], message: "can only review a game once per platform" }

  # Callbacks
  after_initialize :set_default_moderation_status, if: :new_record?

  # Scopes
  scope :approved, -> { where(moderation_status: :approved) }
  scope :pending_moderation, -> { where(moderation_status: :pending) }
  scope :flagged, -> { where(moderation_status: :flagged) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_score, -> { order(score: :desc) }
  scope :for_game, ->(game_id) { where(game_id: game_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  private

  def set_default_moderation_status
    self.moderation_status ||= :pending
  end
end
