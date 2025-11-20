class LeaderboardService
  # The 14 legendary trainer names for the leaderboard slots
  LEGENDARY_TRAINERS = [
    "Red",
    "Blue",
    "Lance",
    "Agatha",
    "Bruno",
    "Lorelei",
    "Giovanni",
    "Blaine",
    "Sabrina",
    "Koga",
    "Erika",
    "Lt Surge",
    "Misty",
    "Brock"
  ].freeze

  def initialize(current_trainer_id)
    @current_trainer_id = current_trainer_id
  end

  # Generate the leaderboard slots with ranked trainers
  # @return [Array<Hash>] array of 14 slot hashes with position, title, and trainer_data
  def slots
    ranked_trainers = fetch_and_rank_trainers
    assign_trainers_to_slots(ranked_trainers)
  end

  private

  def fetch_and_rank_trainers
    # Get all trainers with their captured Pokémon and calculate difficulty scores
    trainers = Trainer.includes(:captured_pokemon, :icon_pokemon).all.map(&:leaderboard_score)

    # Sort by difficulty score (descending), then by pokemon count (descending)
    trainers.sort_by { |t| [-t[:difficulty_score], -t[:pokemon_count]] }
  end

  def assign_trainers_to_slots(ranked_trainers)
    slots = []
    current_slot = 1
    i = 0

    while current_slot <= 14 && i < ranked_trainers.length
      current_entry = ranked_trainers[i]
      tied_trainers = [current_entry]

      # Find all trainers with the same score
      j = i + 1
      while j < ranked_trainers.length &&
            ranked_trainers[j][:difficulty_score] == current_entry[:difficulty_score] &&
            ranked_trainers[j][:pokemon_count] == current_entry[:pokemon_count]
        tied_trainers << ranked_trainers[j]
        j += 1
      end

      # Sort tied trainers to put current user first if they're in the tie
      tied_trainers.sort_by! { |t| t[:trainer].id == @current_trainer_id ? 0 : 1 }

      slots << {
        position: current_slot,
        title: LEGENDARY_TRAINERS[current_slot - 1],
        trainer_data: tied_trainers # Array of tied trainers
      }

      i = j
      current_slot += 1
    end

    # Fill remaining empty slots
    while current_slot <= 14
      slots << {
        position: current_slot,
        title: LEGENDARY_TRAINERS[current_slot - 1],
        trainer_data: nil
      }
      current_slot += 1
    end

    slots
  end
end
