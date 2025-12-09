class GamePlatform < ApplicationRecord
  belongs_to :game
  belongs_to :platform

  # Validations
  validates :game_id, uniqueness: { scope: :platform_id }
end
