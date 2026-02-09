require "test_helper"

class PokedexPartyTest < ActionDispatch::IntegrationTest
  def setup
    @trainer = trainers(:ash)
    @pikachu = pokemons(:pikachu)
    @raichu = pokemons(:raichu)

    # Ensure trainer has captured these pokemon
    @trainer.captures.create!(pokemon: @pikachu, ball_type: "pokeball")
    @trainer.captures.create!(pokemon: @raichu, ball_type: "pokeball")

    log_in_as(@trainer)
  end

  test "pokedex should display party section with 6 slots" do
    get pokedex_path
    assert_response :success

    assert_select ".party-section"
    assert_select ".party-title", text: "Your Party"
    assert_select ".party-slot", count: 6
  end

  test "party section should show empty slots when no party members" do
    get pokedex_path
    assert_response :success

    assert_select ".party-empty", count: 6
  end

  test "party section should show filled slots for party members" do
    PartyMember.create!(trainer: @trainer, pokemon: @pikachu, position: 1)
    PartyMember.create!(trainer: @trainer, pokemon: @raichu, position: 3)

    get pokedex_path
    assert_response :success

    # Should have 2 filled slots
    assert_select ".party-slot.party-filled", count: 2

    # Should have 4 empty slots
    assert_select ".party-empty", count: 4

    # Check that pikachu is shown
    assert_select ".party-pokemon-name", text: @pikachu.name

    # Check that raichu is shown
    assert_select ".party-pokemon-name", text: @raichu.name
  end

  test "party slots should have correct data attributes" do
    PartyMember.create!(trainer: @trainer, pokemon: @pikachu, position: 1)

    get pokedex_path
    assert_response :success

    # Check that all slots have position data attribute
    (1..6).each do |position|
      assert_select ".party-slot[data-position='#{position}']", count: 1
    end

    # Check that filled slot has pokemon-id data attribute
    assert_select ".party-slot[data-position='1'][data-pokemon-id='#{@pikachu.id}']", count: 1
  end

  test "pokemon cards should have pokemon-id data attribute" do
    get pokedex_path
    assert_response :success

    # Check that pokemon cards have data-pokemon-id attribute
    assert_select ".pokemon-card[data-pokemon-id='#{@pikachu.id}']", count: 1
    assert_select ".pokemon-card[data-pokemon-id='#{@raichu.id}']", count: 1
  end

  test "party section should appear before pokedex grid" do
    get pokedex_path
    assert_response :success

    # Get the HTML and check order
    html = response.body
    party_index = html.index('class="party-section"')
    pokedex_index = html.index('class="pokedex-container"')

    assert party_index < pokedex_index, "Party section should appear before pokedex container"
  end

  private

  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end
end
