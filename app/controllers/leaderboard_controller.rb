class LeaderboardController < ApplicationController
  before_action :require_login, only: [:index]

  def index
    @leaderboard_slots = LeaderboardService.new(current_trainer.id).slots
  end
end
