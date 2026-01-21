require "test_helper"

class EliteTrainerControllerTest < ActionDispatch::IntegrationTest
  test "should redirect to dashboard if not enough pokemon" do
    trainer = create_trainer_with_onboarding
    log_in_as(trainer)

    get elite_trainer_congratulations_url
    assert_redirected_to dashboard_path
  end

  test "should show congratulations when 151 pokemon caught" do
    trainer = create_trainer_with_onboarding
    log_in_as(trainer)

    # Create 151 Pokemon if they don't exist
    151.times do |i|
      pokemon = Pokemon.find_or_create_by!(pokedex_number: i + 1) do |p|
        p.name = "Pokemon#{i + 1}"
        p.difficulty = 1
      end
      trainer.captures.create!(pokemon: pokemon, ball_type: 'pokeball', captured_at: Time.current, evolved: false)
    end

    # Verify we have 151 distinct Pokemon
    distinct_count = trainer.captures.select(:pokemon_id).distinct.count
    assert_equal 151, distinct_count, "Trainer should have 151 distinct Pokemon"

    get elite_trainer_congratulations_url
    assert_response :success
  end

  test "should increment elite_trainer_level on confirm" do
    trainer = create_trainer_with_onboarding
    log_in_as(trainer)

    # Create 151 Pokemon if they don't exist
    151.times do |i|
      pokemon = Pokemon.find_or_create_by!(pokedex_number: i + 1) do |p|
        p.name = "Pokemon#{i + 1}"
        p.difficulty = 1
      end
      trainer.captures.create!(pokemon: pokemon, ball_type: 'pokeball', captured_at: Time.current, evolved: false)
    end

    initial_level = trainer.elite_trainer_level

    post elite_trainer_confirm_url
    trainer.reload

    assert_equal initial_level + 1, trainer.elite_trainer_level
    assert_redirected_to onboarding_choose_starter_path
  end

  test "should redirect to dashboard on decline" do
    trainer = create_trainer_with_onboarding
    log_in_as(trainer)

    post elite_trainer_decline_url
    assert_redirected_to dashboard_path
  end

  private

  def create_trainer_with_onboarding
    Trainer.create!(
      username: "elite_#{rand(10000)}",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id,
      onboarding_completed: true
    )
  end

  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end
end
