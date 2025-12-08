class PokeballRewardService
  # Weighted probabilities for each story point value
  # Format: { ball_type => weight }
  REWARD_WEIGHTS = {
    1 => {
      "pokeball" => 80,
      "great_ball" => 10,
      "ultra_ball" => 5,
      "master_ball" => 5
    },
    2 => {
      "pokeball" => 80,
      "great_ball" => 10,
      "ultra_ball" => 5,
      "master_ball" => 5
    },
    3 => {
      "pokeball" => 60,
      "great_ball" => 20,
      "ultra_ball" => 10,
      "master_ball" => 10
    },
    5 => {
      "great_ball" => 60,
      "ultra_ball" => 30,
      "master_ball" => 10
    },
    8 => {
      "ultra_ball" => 75,
      "master_ball" => 25
    }
  }.freeze

  def initialize(trainer, story_points)
    @trainer = trainer
    @story_points = story_points
  end

  def award!
    ball_type = select_ball_type
    @trainer.add_ball!(ball_type)

    {
      ball_type: ball_type,
      story_points: @story_points,
      new_count: @trainer.ball_count(ball_type)
    }
  end

  private

  def select_ball_type
    weights = REWARD_WEIGHTS[@story_points] || default_weights

    # Use weighted random selection
    total = weights.values.sum
    random_value = rand(1..total)

    cumulative = 0
    weights.each do |ball_type, weight|
      cumulative += weight
      return ball_type if random_value <= cumulative
    end

    weights.keys.first # Fallback
  end

  def default_weights
    # For story points not explicitly defined, use a reasonable default
    case @story_points
    when 0..2
      REWARD_WEIGHTS[1]
    when 3..4
      REWARD_WEIGHTS[3]
    when 5..7
      REWARD_WEIGHTS[5]
    else
      REWARD_WEIGHTS[8]
    end
  end
end
