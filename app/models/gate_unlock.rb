class GateUnlock < ApplicationRecord
  belongs_to :trainer
  belongs_to :gate

  validates :trainer_id, uniqueness: { scope: :gate_id, message: "has already unlocked this gate" }
  validates :unlocked_at, presence: true

  before_validation :set_unlocked_at, on: :create
  after_create :award_gate_rewards

  # Gate rewards configuration
  GATE_REWARDS = {
    1 => {
      items: [
        { key: :pokeball, quantity: 1, name: "Poké Ball" }
      ]
    },
    2 => {
      currency: 100,
      items: [
        { key: :old_rod, quantity: 1, name: "Old Rod" },
        { key: :potion, quantity: 1, name: "Potion" }
      ]
    },
    3 => {
      items: [
        { key: :evolution_stone, quantity: 1, name: "Evolution Stone" }
      ]
    },
    4 => {
      items: [
        { key: :great_ball, quantity: 1, name: "Great Ball" },
        { key: :good_rod, quantity: 1, name: "Good Rod" }
      ],
      pokemon: [
        { pokedex_number: 133, ball_type: "pokeball" } # Eevee
      ]
    },
    5 => {
      currency: 200,
      items: [
        { key: :hm_surf, quantity: 1, name: "HM03 Surf" },
        { key: :super_potion, quantity: 1, name: "Super Potion" }
      ],
      pokemon: [
        { pokedex_number: 131, ball_type: "pokeball" } # Lapras
      ]
    },
    6 => {
      items: [
        { key: :evolution_stone, quantity: 2, name: "Evolution Stone" },
        { key: :super_rod, quantity: 1, name: "Super Rod" }
      ]
    },
    7 => {
      items: [
        { key: :ultra_ball, quantity: 1, name: "Ultra Ball" }
      ]
    },
    8 => {
      currency: 500
    },
    9 => {
      items: [
        { key: :master_ball, quantity: 1, name: "Master Ball" }
      ]
    }
  }.freeze

  private

  def set_unlocked_at
    self.unlocked_at ||= Time.current
  end

  def award_gate_rewards
    rewards = GATE_REWARDS[gate.gate_number]
    return unless rewards

    # Award currency if specified
    if rewards[:currency]
      trainer.increment!(:currency, rewards[:currency])
      Rails.logger.info "Awarded #{rewards[:currency]} currency to trainer #{trainer.username} for unlocking gate #{gate.gate_number}"
    end

    # Award items if specified
    if rewards[:items]
      rewards[:items].each do |item_reward|
        item = Item.find_by(key: item_reward[:key].to_s)
        if item
          # For key_items, only award if trainer doesn't already have it
          if item.item_type == "key_item" && trainer.has_item?(item_reward[:key])
            Rails.logger.info "Trainer #{trainer.username} already has #{item_reward[:name]}, skipping duplicate"
          else
            trainer.add_item(item_reward[:key], item_reward[:quantity])
            Rails.logger.info "Awarded #{item_reward[:quantity]}x #{item_reward[:name]} to trainer #{trainer.username} for unlocking gate #{gate.gate_number}"
          end
        else
          Rails.logger.error "Item #{item_reward[:key]} not found when trying to award for gate #{gate.gate_number}"
        end
      end
    end

    # Award pokemon if specified
    if rewards[:pokemon]
      rewards[:pokemon].each do |pokemon_reward|
        pokemon = Pokemon.find_by(pokedex_number: pokemon_reward[:pokedex_number])
        if pokemon
          # Check if trainer already has this pokemon
          unless trainer.captured_pokemon.exists?(id: pokemon.id)
            trainer.captures.create!(
              pokemon: pokemon,
              ball_type: pokemon_reward[:ball_type] || "pokeball"
            )
            Rails.logger.info "Awarded #{pokemon.name} to trainer #{trainer.username} for unlocking gate #{gate.gate_number}"
          else
            Rails.logger.info "Trainer #{trainer.username} already has #{pokemon.name}, skipping duplicate"
          end
        else
          Rails.logger.error "Pokemon ##{pokemon_reward[:pokedex_number]} not found when trying to award for gate #{gate.gate_number}"
        end
      end
    end
  end
end
