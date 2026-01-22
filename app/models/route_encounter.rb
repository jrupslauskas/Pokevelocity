class RouteEncounter < ApplicationRecord
  belongs_to :route
  belongs_to :pokemon
  belongs_to :required_pokemon, class_name: "Pokemon", optional: true
  belongs_to :alternative_required_pokemon, class_name: "Pokemon", optional: true

  enum :encounter_type, { grass: "grass", fish: "fish", surf: "surf" }, validate: true

  validates :spawn_rate, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :encounter_type, presence: true
  validates :pokemon_id, uniqueness: { scope: [ :route_id, :encounter_type, :required_item_key ],
            message: "already exists on this route for this encounter type and item requirement" }
  validates :required_gate_number,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10, allow_nil: true }

  # Check if a trainer meets the requirements to encounter this Pokemon
  def available_for?(trainer)
    # Check Pokemon requirement (OR logic if alternative exists)
    if required_pokemon_id.present?
      has_required = trainer.captured_pokemon.exists?(id: required_pokemon_id)

      if alternative_required_pokemon_id.present?
        has_alternative = trainer.captured_pokemon.exists?(id: alternative_required_pokemon_id)
        return false unless has_required || has_alternative
      else
        return false unless has_required
      end
    end

    # Check gate requirement
    if required_gate_number.present?
      required_gate = Gate.find_by(gate_number: required_gate_number)
      return false unless required_gate && trainer.has_unlocked_gate?(required_gate)
    end

    # Check item requirement (for fishing rods, etc.)
    if required_item_key.present?
      # Handle fishing rod hierarchy: better rods can catch lower-tier Pokemon
      case required_item_key
      when "old_rod"
        return false unless trainer.has_item?(:old_rod) || trainer.has_item?(:good_rod) || trainer.has_item?(:super_rod)
      when "good_rod"
        return false unless trainer.has_item?(:good_rod) || trainer.has_item?(:super_rod)
      when "super_rod"
        return false unless trainer.has_item?(:super_rod)
      else
        # For other items (like hm_surf), require exact match
        return false unless trainer.has_item?(required_item_key)
      end
    end

    true
  end

  # Get a human-readable string of requirements
  def requirement_description
    requirements = []

    # Handle Pokemon requirement (with OR logic if alternative exists)
    if required_pokemon_id.present?
      if alternative_required_pokemon_id.present?
        requirements << "#{required_pokemon.name} or #{alternative_required_pokemon.name}"
      else
        requirements << "#{required_pokemon.name}"
      end
    end

    if required_gate_number.present?
      gate = Gate.find_by(gate_number: required_gate_number)
      requirements << gate&.name if gate
    end

    if required_item_key.present?
      item = Item.find_by(key: required_item_key)
      requirements << item&.name if item
    end

    requirements.any? ? "Requires: #{requirements.join(' & ')}" : nil
  end
end
