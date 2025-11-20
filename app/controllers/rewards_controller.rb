class RewardsController < ApplicationController
  before_action :require_login

  def index
    @trainer = current_trainer
  end

  def create
    @trainer = current_trainer
    story_points = params[:story_points].to_i

    if story_points > 0
      result = @trainer.award_pokeball_for_ticket(story_points)
      redirect_to rewards_path, notice: "Congratulations! You earned a #{result[:ball_type].humanize} for completing a #{story_points} point ticket!"
    else
      redirect_to rewards_path, alert: "Please enter a valid story point value"
    end
  end
end
