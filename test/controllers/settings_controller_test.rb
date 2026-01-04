require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  def log_in_as(trainer)
    post login_path, params: { username: trainer.username, password: "password" }
  end

  # ================================================================================
  # AUTHENTICATION TESTS
  # ================================================================================

  test "should redirect to login when not authenticated" do
    get edit_settings_path
    assert_redirected_to login_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  test "should allow authenticated user to view settings" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get edit_settings_path
    assert_response :success
  end

  # ================================================================================
  # EDIT PAGE TESTS
  # ================================================================================

  test "should display current pokemon icon in settings" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get edit_settings_path
    assert_response :success
    assert_match /Current Icon/, response.body
  end

  test "should display all pokemon options in settings" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get edit_settings_path
    assert_response :success
    assert_select ".icon-pokemon-grid"
    assert_select "input[name='icon_pokemon_id']", minimum: 1
  end

  test "should display trainer sprite options in settings" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get edit_settings_path
    assert_response :success
    assert_select "input[name='icon_trainer_sprite']", minimum: 1
  end

  # ================================================================================
  # UPDATE TESTS - POKEMON ICON
  # ================================================================================

  test "should successfully update trainer pokemon icon" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    new_pokemon = pokemons(:bulbasaur)

    patch update_settings_path, params: { icon_pokemon_id: new_pokemon.id }

    assert_redirected_to edit_settings_path
    assert_equal "Settings updated successfully!", flash[:notice]

    trainer.reload
    assert_equal new_pokemon.id, trainer.icon_pokemon_id
    assert_nil trainer.icon_trainer_sprite
  end

  test "should clear trainer sprite when updating to pokemon icon" do
    trainer = trainers(:gary)
    trainer.update!(icon_trainer_sprite: "ace-trainer-m", icon_pokemon_id: nil)
    log_in_as(trainer)

    new_pokemon = pokemons(:pikachu)

    patch update_settings_path, params: { icon_pokemon_id: new_pokemon.id }

    trainer.reload
    assert_equal new_pokemon.id, trainer.icon_pokemon_id
    assert_nil trainer.icon_trainer_sprite
  end

  # ================================================================================
  # UPDATE TESTS - TRAINER SPRITE
  # ================================================================================

  test "should successfully update trainer sprite icon" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    new_sprite = "ace-trainer-f"

    patch update_settings_path, params: { icon_trainer_sprite: new_sprite }

    assert_redirected_to edit_settings_path
    assert_equal "Settings updated successfully!", flash[:notice]

    trainer.reload
    assert_equal new_sprite, trainer.icon_trainer_sprite
    assert_nil trainer.icon_pokemon_id
  end

  test "should clear pokemon icon when updating to trainer sprite" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    new_sprite = "cooltrainer-m"

    patch update_settings_path, params: { icon_trainer_sprite: new_sprite }

    trainer.reload
    assert_equal new_sprite, trainer.icon_trainer_sprite
    assert_nil trainer.icon_pokemon_id
  end

  # ================================================================================
  # VALIDATION TESTS
  # ================================================================================

  test "should not update without any icon selection" do
    trainer = trainers(:ash)
    original_icon_id = trainer.icon_pokemon_id
    log_in_as(trainer)

    patch update_settings_path, params: {}

    trainer.reload
    assert_equal original_icon_id, trainer.icon_pokemon_id
  end

  test "should maintain session after updating settings" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    patch update_settings_path, params: { icon_pokemon_id: pokemons(:bulbasaur).id }

    assert_equal trainer.id, session[:trainer_id]
  end

  # ================================================================================
  # INTEGRATION TESTS
  # ================================================================================

  test "should allow changing icon multiple times" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    # Change to Bulbasaur
    patch update_settings_path, params: { icon_pokemon_id: pokemons(:bulbasaur).id }
    trainer.reload
    assert_equal pokemons(:bulbasaur).id, trainer.icon_pokemon_id

    # Change to a trainer sprite
    patch update_settings_path, params: { icon_trainer_sprite: "ace-trainer-m" }
    trainer.reload
    assert_equal "ace-trainer-m", trainer.icon_trainer_sprite
    assert_nil trainer.icon_pokemon_id

    # Change back to a pokemon
    patch update_settings_path, params: { icon_pokemon_id: pokemons(:pikachu).id }
    trainer.reload
    assert_equal pokemons(:pikachu).id, trainer.icon_pokemon_id
    assert_nil trainer.icon_trainer_sprite
  end

  test "sidebar should display settings link" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get dashboard_path
    assert_response :success
    assert_select "a.sidebar-settings-link[href=?]", edit_settings_path
  end

  # ================================================================================
  # GAMEPLAY TAB TESTS
  # ================================================================================

  test "should display icons tab button" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get edit_settings_path
    assert_response :success
    assert_select "button.settings-tab", text: "Icons"
  end

  test "should display gameplay tab button" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get edit_settings_path
    assert_response :success
    assert_select "button.settings-tab", text: "Gameplay"
  end

  test "should display icons tab content" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get edit_settings_path
    assert_response :success
    assert_select "#icons-tab.settings-tab-content"
  end

  test "should display gameplay tab content" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get edit_settings_path
    assert_response :success
    assert_select "#gameplay-tab.settings-tab-content"
  end

  test "icons tab should be active by default" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get edit_settings_path
    assert_response :success
    assert_select "#icons-tab.settings-tab-content.active"
  end

  test "gameplay tab should not be active by default" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get edit_settings_path
    assert_response :success
    assert_select "#gameplay-tab.settings-tab-content.active", count: 0
  end

  # ================================================================================
  # ENCOUNTER ANIMATION PREFERENCE TESTS
  # ================================================================================

  test "new trainers should have encounter animation disabled by default" do
    trainer = Trainer.create!(
      username: "newtrainer",
      password: "password",
      icon_pokemon_id: pokemons(:pikachu).id
    )
    assert_equal false, trainer.show_encounter_animation
  end

  test "should display encounter animation checkbox in gameplay tab" do
    trainer = trainers(:ash)
    log_in_as(trainer)

    get edit_settings_path
    assert_response :success
    assert_select "input#show_encounter_animation[type='checkbox']"
    assert_select "label[for='show_encounter_animation']", text: "Display Encounter Animation"
  end

  test "encounter animation checkbox should be unchecked when preference is false" do
    trainer = trainers(:ash)
    trainer.update!(show_encounter_animation: false)
    log_in_as(trainer)

    get edit_settings_path
    assert_response :success
    assert_select "input#show_encounter_animation[checked]", count: 0
  end

  test "encounter animation checkbox should be checked when preference is true" do
    trainer = trainers(:ash)
    trainer.update!(show_encounter_animation: true)
    log_in_as(trainer)

    get edit_settings_path
    assert_response :success
    assert_select "input#show_encounter_animation[checked='checked']"
  end

  test "should enable encounter animation when checkbox is checked" do
    trainer = trainers(:ash)
    trainer.update!(show_encounter_animation: false)
    log_in_as(trainer)

    patch update_settings_path, params: { show_encounter_animation: "1" }

    assert_redirected_to edit_settings_path
    assert_equal "Settings updated successfully!", flash[:notice]

    trainer.reload
    assert_equal true, trainer.show_encounter_animation
  end

  test "should disable encounter animation when checkbox is unchecked" do
    trainer = trainers(:ash)
    trainer.update!(show_encounter_animation: true)
    log_in_as(trainer)

    # When checkbox is unchecked, the parameter is not sent at all
    # We need to explicitly set it to "0" or handle the absence
    patch update_settings_path, params: { show_encounter_animation: "0" }

    trainer.reload
    assert_equal false, trainer.show_encounter_animation
  end

  test "should not modify encounter animation preference when updating other settings" do
    trainer = trainers(:ash)
    trainer.update!(show_encounter_animation: true)
    log_in_as(trainer)

    new_pokemon = pokemons(:bulbasaur)
    patch update_settings_path, params: { icon_pokemon_id: new_pokemon.id }

    trainer.reload
    assert_equal new_pokemon.id, trainer.icon_pokemon_id
    # Animation preference should remain unchanged
    assert_equal true, trainer.show_encounter_animation
  end

  test "should update both icon and animation preference in same request" do
    trainer = trainers(:ash)
    trainer.update!(show_encounter_animation: false)
    log_in_as(trainer)

    new_pokemon = pokemons(:bulbasaur)
    patch update_settings_path, params: {
      icon_pokemon_id: new_pokemon.id,
      show_encounter_animation: "1"
    }

    trainer.reload
    assert_equal new_pokemon.id, trainer.icon_pokemon_id
    assert_equal true, trainer.show_encounter_animation
  end
end
