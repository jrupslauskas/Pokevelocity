class PokeballRewardService
  # Weighted probabilities for each story point value
  # Format: { ball_type => weight }
  REWARD_WEIGHTS = {
    1 => {
      "pokeball" => 95,
      "great_ball" => 5
    },
    3 => {
      "pokeball" => 75,
      "great_ball" => 25
    },
    5 => {
      "pokeball" => 5,
      "great_ball" => 75,
      "ultra_ball" => 20
    },
    8 => {
      "great_ball" => 5,
      "ultra_ball" => 80,
      "master_ball" => 15
    },
    13 => {
      "ultra_ball" => 70,
      "master_ball" => 30
    }
  }.freeze

  def initialize(trainer, story_points)
    @trainer = trainer
    @story_points = story_points
  end

  def award!
    ball_type = select_ball_type
    increment_ball_count(ball_type)
    @trainer.save!

    {
      ball_type: ball_type,
      story_points: @story_points,
      new_count: ball_count_for(ball_type)
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

  def increment_ball_count(ball_type)
    case ball_type
    when "pokeball"
      @trainer.pokeballs_count += 1
    when "great_ball"
      @trainer.great_balls_count += 1
    when "ultra_ball"
      @trainer.ultra_balls_count += 1
    when "master_ball"
      @trainer.master_balls_count += 1
    end
  end

  def ball_count_for(ball_type)
    case ball_type
    when "pokeball"
      @trainer.pokeballs_count
    when "great_ball"
      @trainer.great_balls_count
    when "ultra_ball"
      @trainer.ultra_balls_count
    when "master_ball"
      @trainer.master_balls_count
    end
  end
end
