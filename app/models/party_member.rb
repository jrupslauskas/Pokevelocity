class PartyMember < ApplicationRecord
  belongs_to :trainer
  belongs_to :pokemon

  validates :position, presence: true, inclusion: { in: 1..6 }
  validates :trainer_id, uniqueness: { scope: :position, message: "already has a Pokémon in this position" }
  validates :pokemon_id, uniqueness: { scope: :trainer_id, message: "is already in your party" }

  # Validate that the trainer has actually caught this Pokémon
  validate :trainer_must_have_caught_pokemon

  private

  def trainer_must_have_caught_pokemon
    return unless trainer && pokemon

    unless trainer.captured_pokemon.exists?(id: pokemon.id)
      errors.add(:pokemon, "must be caught before adding to party")
    end
  end
end
