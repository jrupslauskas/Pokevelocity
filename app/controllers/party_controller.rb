class PartyController < ApplicationController
  before_action :require_login

  # Update a specific party slot
  # POST /party/update_slot
  # Params: position (1-6), pokemon_id (or nil to clear slot)
  def update_slot
    @trainer = current_trainer
    position = params[:position].to_i
    pokemon_id = params[:pokemon_id].presence

    # Validate position
    unless (1..6).include?(position)
      render json: { success: false, error: "Invalid position" }, status: :unprocessable_entity
      return
    end

    # If clearing slot (pokemon_id is nil or empty)
    if pokemon_id.nil?
      party_member = @trainer.party_members.find_by(position: position)
      if party_member
        party_member.destroy
        render json: { success: true, action: "removed" }, status: :ok
      else
        render json: { success: true, action: "already_empty" }, status: :ok
      end
      return
    end

    # Find the pokemon
    pokemon = Pokemon.find_by(id: pokemon_id)
    unless pokemon
      render json: { success: false, error: "Pokémon not found" }, status: :not_found
      return
    end

    # Check if trainer has caught this pokemon
    unless @trainer.captured_pokemon.exists?(id: pokemon.id)
      render json: { success: false, error: "You haven't caught this Pokémon yet" }, status: :forbidden
      return
    end

    # Check if pokemon is already in party (different position)
    existing_member = @trainer.party_members.find_by(pokemon_id: pokemon_id)
    if existing_member && existing_member.position != position
      render json: { success: false, error: "This Pokémon is already in your party" }, status: :unprocessable_entity
      return
    end

    # If pokemon is already in the same position, just return success
    if existing_member && existing_member.position == position
      sprite_filename = "pokemonSprites/#{pokemon.pokedex_number.to_s.rjust(3, '0')}.png"
      sprite_url = ActionController::Base.helpers.image_path(sprite_filename)

      render json: {
        success: true,
        action: "added",
        pokemon: {
          id: pokemon.id,
          name: pokemon.name,
          pokedex_number: pokemon.pokedex_number.to_s.rjust(3, '0'),
          sprite_url: sprite_url
        }
      }, status: :ok
      return
    end

    # Remove existing party member at this position if present, then create new one
    existing_at_position = @trainer.party_members.find_by(position: position)
    existing_at_position&.destroy

    party_member = @trainer.party_members.create!(
      pokemon: pokemon,
      position: position
    )

    # Generate proper asset path for the sprite
    sprite_filename = "pokemonSprites/#{pokemon.pokedex_number.to_s.rjust(3, '0')}.png"
    sprite_url = ActionController::Base.helpers.image_path(sprite_filename)

    render json: {
      success: true,
      action: "added",
      pokemon: {
        id: pokemon.id,
        name: pokemon.name,
        pokedex_number: pokemon.pokedex_number.to_s.rjust(3, '0'),
        sprite_url: sprite_url
      }
    }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end
end
