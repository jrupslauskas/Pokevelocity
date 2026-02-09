require "test_helper"

class PartyControllerTest < ActionDispatch::IntegrationTest
  def setup
    @trainer = trainers(:ash)
    @pikachu = pokemons(:pikachu)
    @raichu = pokemons(:raichu)
    @voltorb = Pokemon.create!(name: "Voltorb", pokedex_number: 100, difficulty: 2)

    # Ensure trainer has captured these pokemon
    @trainer.captures.create!(pokemon: @pikachu, ball_type: "pokeball")
    @trainer.captures.create!(pokemon: @raichu, ball_type: "pokeball")

    log_in_as(@trainer)
  end

  test "should add pokemon to empty party slot" do
    assert_difference("PartyMember.count", 1) do
      post update_party_slot_path, params: { position: 1, pokemon_id: @pikachu.id }, as: :json
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "added", json_response["action"]
    assert_equal @pikachu.id, json_response["pokemon"]["id"]
    assert_equal "025", json_response["pokemon"]["pokedex_number"]
    assert_not_nil json_response["pokemon"]["sprite_url"]
    assert_includes json_response["pokemon"]["sprite_url"], "pokemonSprites"
  end

  test "should replace pokemon in occupied slot" do
    PartyMember.create!(trainer: @trainer, pokemon: @pikachu, position: 1)

    assert_no_difference("PartyMember.count") do
      post update_party_slot_path, params: { position: 1, pokemon_id: @raichu.id }, as: :json
    end

    assert_response :success
    party_member = @trainer.party_members.find_by(position: 1)
    assert_equal @raichu.id, party_member.pokemon_id
  end

  test "should remove pokemon from party slot" do
    PartyMember.create!(trainer: @trainer, pokemon: @pikachu, position: 1)

    assert_difference("PartyMember.count", -1) do
      post update_party_slot_path, params: { position: 1, pokemon_id: nil }, as: :json
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "removed", json_response["action"]
  end

  test "should return error for invalid position" do
    post update_party_slot_path, params: { position: 0, pokemon_id: @pikachu.id }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_equal "Invalid position", json_response["error"]
  end

  test "should return error for position above 6" do
    post update_party_slot_path, params: { position: 7, pokemon_id: @pikachu.id }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_equal "Invalid position", json_response["error"]
  end

  test "should return error for pokemon not found" do
    post update_party_slot_path, params: { position: 1, pokemon_id: 999999 }, as: :json

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_equal "Pokémon not found", json_response["error"]
  end

  test "should return error for uncaught pokemon" do
    post update_party_slot_path, params: { position: 1, pokemon_id: @voltorb.id }, as: :json

    assert_response :forbidden
    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_equal "You haven't caught this Pokémon yet", json_response["error"]
  end

  test "should return error when adding duplicate pokemon to different position" do
    PartyMember.create!(trainer: @trainer, pokemon: @pikachu, position: 1)

    post update_party_slot_path, params: { position: 2, pokemon_id: @pikachu.id }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_equal "This Pokémon is already in your party", json_response["error"]
  end

  test "should allow updating same position with same pokemon" do
    PartyMember.create!(trainer: @trainer, pokemon: @pikachu, position: 1)

    assert_no_difference("PartyMember.count") do
      post update_party_slot_path, params: { position: 1, pokemon_id: @pikachu.id }, as: :json
    end

    assert_response :success
  end

  test "should require login" do
    delete logout_path
    post update_party_slot_path, params: { position: 1, pokemon_id: @pikachu.id }, as: :json

    assert_redirected_to login_path
  end

  test "clearing empty slot returns success" do
    post update_party_slot_path, params: { position: 1, pokemon_id: nil }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "already_empty", json_response["action"]
  end

  private

  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end
end
