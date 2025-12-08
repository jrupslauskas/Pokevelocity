class RouteEncounter < ApplicationRecord
  belongs_to :route
  belongs_to :pokemon
  belongs_to :required_pokemon, class_name: "Pokemon", optional: true
  belongs_to :alternative_required_pokemon, class_name: "Pokemon", optional: true

  validates :spawn_rate, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :pokemon_id, uniqueness: { scope: :route_id,
            message: "already exists on this route" }
  validates :required_gate_number,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10, allow_nil: true }

  # Check if a trainer meets the requirements to encounter this Pokemon
  def available_for?(trainer)
    # Check Pokemon requirement (OR logic if alternative exists)
    if required_pokemon_id.present?
      has_required = trainer.captured_pokemon.exists?(id: required_pokemon_id)

      if alternative_required_pokemon_id.present?
        has_alternative = trainer.captured_pokemon.exists?(id: alternative_required_pokemon_id)
        return false unless (has_required || has_alternative)
      else
        return false unless has_required
      end
    end

    # Check gate requirement
    if required_gate_number.present?
      required_gate = Gate.find_by(gate_number: required_gate_number)
      return false unless required_gate && trainer.has_unlocked_gate?(required_gate)
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

    requirements.any? ? "Requires: #{requirements.join(' & ')}" : nil
  end
end
