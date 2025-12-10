require "test_helper"

class GameMetascoreUpdateJobTest < ActiveJob::TestCase
  setup do
    # Clean database
    Game.destroy_all
    Publisher.destroy_all
    Developer.destroy_all
    Publication.destroy_all
    CriticReview.destroy_all

    # Create test data
    @publisher = Publisher.create!(name: "Test Publisher")
    @developer = Developer.create!(name: "Test Developer")
    @game = Game.create!(
      title: "Test Game",
      publisher: @publisher,
      developer: @developer,
      release_date: 1.month.ago,
      rating_category: :everyone,
      metascore: 0
    )

    @publication1 = Publication.create!(
      name: "High Credibility Publication",
      credibility_weight: 9.0
    )

    @publication2 = Publication.create!(
      name: "Medium Credibility Publication",
      credibility_weight: 5.0
    )
  end

  test "updates metascore for specific game with critic reviews" do
    # Create critic reviews
    CriticReview.create!(game: @game, publication: @publication1, score: 90)
    CriticReview.create!(game: @game, publication: @publication2, score: 70)

    # Expected: (90 * 9.0 + 70 * 5.0) / (9.0 + 5.0) = 1160 / 14 = 82.857... ≈ 83
    GameMetascoreUpdateJob.perform_now(@game.id)

    assert_equal 83, @game.reload.metascore
  end

  test "does not update metascore when no critic reviews exist" do
    initial_metascore = @game.metascore

    GameMetascoreUpdateJob.perform_now(@game.id)

    assert_equal initial_metascore, @game.reload.metascore
  end

  test "updates all games when no game_id provided" do
    game2 = Game.create!(
      title: "Another Game",
      publisher: @publisher,
      developer: @developer,
      release_date: 2.months.ago,
      rating_category: :teen,
      metascore: 0
    )

    CriticReview.create!(game: @game, publication: @publication1, score: 95)
    CriticReview.create!(game: game2, publication: @publication2, score: 60)

    GameMetascoreUpdateJob.perform_now

    assert_equal 95, @game.reload.metascore
    assert_equal 60, game2.reload.metascore
  end

  test "calculates correct weighted average with multiple reviews" do
    pub3 = Publication.create!(name: "Low Credibility", credibility_weight: 2.0)

    CriticReview.create!(game: @game, publication: @publication1, score: 100) # weight 9.0
    CriticReview.create!(game: @game, publication: @publication2, score: 80)  # weight 5.0
    CriticReview.create!(game: @game, publication: pub3, score: 40)           # weight 2.0

    # Expected: (100*9 + 80*5 + 40*2) / (9 + 5 + 2) = (900 + 400 + 80) / 16 = 1380 / 16 = 86.25 ≈ 86
    GameMetascoreUpdateJob.perform_now(@game.id)

    assert_equal 86, @game.reload.metascore
  end

  test "job is enqueued on background queue" do
    assert_enqueued_with(job: GameMetascoreUpdateJob, queue: "background") do
      GameMetascoreUpdateJob.perform_later(@game.id)
    end
  end
end
