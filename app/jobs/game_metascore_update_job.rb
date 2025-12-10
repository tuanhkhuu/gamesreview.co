# Background job to update game metascores based on critic reviews
# This job recalculates the weighted metascore for a game using all its critic reviews
class GameMetascoreUpdateJob < ApplicationJob
  queue_as :background

  # Update metascore for a specific game or all games
  # @param game_id [Integer, nil] Optional game ID. If nil, updates all games
  def perform(game_id = nil)
    if game_id
      update_game_metascore(Game.find(game_id))
    else
      Game.find_each do |game|
        update_game_metascore(game)
      end
    end
  end

  private

  def update_game_metascore(game)
    critic_reviews = game.critic_reviews.includes(:publication)

    return if critic_reviews.empty?

    # Calculate weighted average based on publication credibility
    total_weight = 0
    weighted_sum = 0

    critic_reviews.each do |review|
      weight = review.publication.credibility_weight
      weighted_sum += review.score * weight
      total_weight += weight
    end

    # Round to nearest integer
    new_metascore = (weighted_sum / total_weight).round

    game.update(metascore: new_metascore)
    Rails.logger.info "Updated metascore for game #{game.id} (#{game.title}): #{new_metascore}"
  end
end
