class GameGenre < ApplicationRecord
  belongs_to :game
  belongs_to :genre

  # Validations
  validates :game_id, uniqueness: { scope: :genre_id }
end
