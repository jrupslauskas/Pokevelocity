require "test_helper"

class LeaderboardControllerTest < ActionDispatch::IntegrationTest
  # ================================================================================
  # AUTHENTICATION TESTS
  # ================================================================================

  test "should require login to view leaderboard" do
    get leaderboard_path
    assert_redirected_to login_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  test "should show leaderboard when logged in" do
    log_in_as(trainers(:ash))
    get leaderboard_path
    assert_response :success
    assert_select "h1", "Indigo Plateau Leaderboard"
  end

  # ================================================================================
  # DISPLAY TESTS
  # ================================================================================

  test "should display trainer username on leaderboard" do
    trainer = trainers(:gary)
    log_in_as(trainer)

    get leaderboard_path

    assert_response :success
    # Gary should appear on the leaderboard
    assert_select ".leaderboard-username", text: /gary/
  end

  test "should display difficulty score on leaderboard" do
    log_in_as(trainers(:gary))

    get leaderboard_path

    assert_response :success
    # Should show difficulty score label
    assert_select ".stat-label", text: "Difficulty Score"
  end

  test "should display pokemon count on leaderboard" do
    log_in_as(trainers(:gary))

    get leaderboard_path

    assert_response :success
    # Should show Pokédex label
    assert_select ".stat-label", text: "Pokédex"
  end

  # ================================================================================
  # LEGENDARY TRAINER NAMES TESTS
  # ================================================================================

  test "should display tier names for all slots" do
    log_in_as(trainers(:ash))
    get leaderboard_path

    assert_response :success
    # Check for a few tier names
    assert_select ".leaderboard-tier-name", text: "1 - Red Tier"
    assert_select ".leaderboard-tier-name", text: "2 - Blue Tier"
    assert_select ".leaderboard-tier-name", text: "3 - Lance Tier"
  end

  test "should display tier name for top slot" do
    log_in_as(trainers(:gary))
    get leaderboard_path

    assert_response :success
    # First slot should be Red Tier
    assert_match "1 - Red Tier", response.body
  end

  test "should display tier names for all 14 slots" do
    log_in_as(trainers(:ash))
    get leaderboard_path

    assert_response :success
    # Should have 14 tier name elements
    assert_select ".leaderboard-tier-name", count: 14
  end

  test "should display tier names even for empty slots" do
    log_in_as(trainers(:ash))
    get leaderboard_path

    assert_response :success
    # Check that tier names appear with empty slots
    # Bottom tier should be present
    assert_select ".leaderboard-tier-name", text: "14 - Brock Tier"
  end

  test "should show unclaimed slots" do
    log_in_as(trainers(:ash))
    get leaderboard_path

    # Should have unclaimed text for empty slots
    assert_select ".leaderboard-empty-text", text: "Unclaimed"
  end

  test "should show current user badge" do
    log_in_as(trainers(:gary))
    get leaderboard_path

    # Should show "You" badge for current user
    assert_select ".you-badge", text: "You"
  end

  # ================================================================================
  # PARTY TOOLTIP TESTS
  # ================================================================================

  test "should render party tooltip element for each trainer card" do
    log_in_as(trainers(:gary))
    get leaderboard_path

    assert_response :success
    assert_select ".party-tooltip"
  end

  test "should display Party label inside party tooltip" do
    log_in_as(trainers(:gary))
    get leaderboard_path

    assert_response :success
    assert_select ".party-tooltip-label", text: "Party"
  end

  test "should show pokemon sprites in party tooltip when trainer has party members" do
    trainer = trainers(:gary)
    # Gary has charmander and squirtle captured via fixtures
    PartyMember.create!(trainer: trainer, pokemon: pokemons(:charmander), position: 1)
    PartyMember.create!(trainer: trainer, pokemon: pokemons(:squirtle), position: 2)

    log_in_as(trainer)
    get leaderboard_path

    assert_response :success
    assert_select ".party-tooltip-pokemon-row"
    assert_select ".party-tooltip-pokemon img[alt=?]", "Charmander"
    assert_select ".party-tooltip-pokemon img[alt=?]", "Squirtle"
  end

  test "should show no party set message when trainer has no party members" do
    # broke_trainer has no captures and no party members
    log_in_as(trainers(:broke_trainer))
    get leaderboard_path

    assert_response :success
    assert_select ".party-tooltip-empty", text: "No party set"
  end

  # ================================================================================
  # PROFILE LINK TESTS
  # ================================================================================

  test "should link trainer card to their pokedex page" do
    log_in_as(trainers(:ash))
    get leaderboard_path

    assert_response :success
    assert_select "a.leaderboard-trainer[href=?]", trainer_path(trainers(:gary))
  end

  test "should link current user trainer card to own pokedex page" do
    log_in_as(trainers(:gary))
    get leaderboard_path

    assert_response :success
    assert_select "a.leaderboard-trainer[href=?]", pokedex_path
  end

  private

  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end
end
