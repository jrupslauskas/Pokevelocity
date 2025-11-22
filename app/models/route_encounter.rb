class RouteEncounter < ApplicationRecord
  belongs_to :route
  belongs_to :pokemon

  validates :spawn_rate, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :pokemon_id, uniqueness: { scope: :route_id,
            message: "already exists on this route" }
end
