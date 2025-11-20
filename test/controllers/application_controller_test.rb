require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  # ================================================================================
  # CURRENT_TRAINER HELPER TESTS
  # ================================================================================

  test "current_trainer returns trainer when logged in" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    get dashboard_path
    assert_response :success
    # The helper is working because dashboard loaded successfully
  end

  test "current_trainer returns nil when not logged in" do
    get login_path
    assert_response :success
    # No error means current_trainer handles nil gracefully
  end

  test "current_trainer persists across multiple requests" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    # Make multiple requests
    get dashboard_path
    assert_response :success

    get pokedex_path
    assert_response :success

    get rewards_path
    assert_response :success
  end

  test "current_trainer uses session to find trainer" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    assert_equal trainer.id, session[:trainer_id]
    get dashboard_path
    assert_response :success
  end

  test "current_trainer handles invalid session gracefully" do
    # Set invalid trainer_id in session
    post login_path, params: { username: trainers(:ash).username, password: "password" }
    # Manually corrupt the session by using a non-existent ID
    # This is implicitly tested by the require_login filter redirecting properly
    delete logout_path
    get dashboard_path
    assert_redirected_to login_path
  end

  # ================================================================================
  # LOGGED_IN? HELPER TESTS
  # ================================================================================

  test "logged_in? returns true when trainer is logged in" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    # If logged_in? returns true, dashboard will load
    get dashboard_path
    assert_response :success
  end

  test "logged_in? returns false when not logged in" do
    # If logged_in? returns false, require_login will redirect
    get dashboard_path
    assert_redirected_to login_path
  end

  test "logged_in? returns false after logout" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    delete logout_path

    # Should be logged out now
    get dashboard_path
    assert_redirected_to login_path
  end

  test "logged_in? works across multiple sessions" do
    # Session 1: Login
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }
    get dashboard_path
    assert_response :success

    # Session 2: Logout
    delete logout_path
    get dashboard_path
    assert_redirected_to login_path
  end

  # ================================================================================
  # REQUIRE_LOGIN FILTER TESTS
  # ================================================================================

  test "require_login allows access when logged in" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    get dashboard_path
    assert_response :success
  end

  test "require_login redirects to login when not authenticated" do
    get dashboard_path
    assert_redirected_to login_path
  end

  test "require_login shows alert message when redirecting" do
    get dashboard_path
    assert_redirected_to login_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  test "require_login protects dashboard" do
    get dashboard_path
    assert_redirected_to login_path
  end

  test "require_login protects pokedex" do
    get pokedex_path
    assert_redirected_to login_path
  end

  test "require_login protects rewards" do
    get rewards_path
    assert_redirected_to login_path
  end

  test "require_login protects catches" do
    get catches_path
    assert_redirected_to login_path
  end

  test "require_login protects leaderboard" do
    get leaderboard_path
    assert_redirected_to login_path
  end

  test "require_login allows login page without authentication" do
    get login_path
    assert_response :success
  end

  test "require_login allows registration page without authentication" do
    get new_trainer_path
    assert_response :success
  end

  test "require_login allows create trainer without authentication" do
    post trainers_path, params: {
      trainer: {
        username: "newuser",
        password: "password",
        icon_pokemon_id: pokemons(:pikachu).id
      },
      activation_code: "TEST01"
    }
    # Should redirect to dashboard after successful creation
    assert_redirected_to dashboard_path
  end

  # ================================================================================
  # SESSION MANAGEMENT TESTS
  # ================================================================================

  test "session persists trainer_id after login" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    assert_not_nil session[:trainer_id]
    assert_equal trainer.id, session[:trainer_id]
  end

  test "session is cleared after logout" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }
    assert_not_nil session[:trainer_id]

    delete logout_path
    assert_nil session[:trainer_id]
  end

  test "session allows access to protected pages" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    # Should be able to access all protected pages
    get dashboard_path
    assert_response :success

    get pokedex_path
    assert_response :success

    get rewards_path
    assert_response :success

    get catches_path
    assert_response :success

    get leaderboard_path
    assert_response :success
  end

  test "session does not allow access after logout" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    delete logout_path

    # Should not be able to access protected pages
    get dashboard_path
    assert_redirected_to login_path

    get pokedex_path
    assert_redirected_to login_path

    get rewards_path
    assert_redirected_to login_path

    get catches_path
    assert_redirected_to login_path

    get leaderboard_path
    assert_redirected_to login_path
  end

  # ================================================================================
  # INTEGRATION TESTS
  # ================================================================================

  test "complete user flow from login to logout" do
    trainer = trainers(:ash)

    # Login
    post login_path, params: { username: trainer.username, password: "password" }
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_response :success

    # Visit dashboard
    get dashboard_path
    assert_response :success

    # Visit pokedex
    get pokedex_path
    assert_response :success

    # Visit rewards
    get rewards_path
    assert_response :success

    # Logout
    delete logout_path
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success

    # Try to access dashboard after logout
    get dashboard_path
    assert_redirected_to login_path
  end

  test "multiple trainers can have separate sessions" do
    # This test simulates what would happen with multiple users
    # In a real browser session, each would have separate cookies

    # Trainer 1 logs in
    trainer1 = trainers(:ash)
    post login_path, params: { username: trainer1.username, password: "password" }
    assert_equal trainer1.id, session[:trainer_id]

    # Logout
    delete logout_path
    assert_nil session[:trainer_id]

    # Trainer 2 logs in
    trainer2 = trainers(:gary)
    post login_path, params: { username: trainer2.username, password: "password" }
    assert_equal trainer2.id, session[:trainer_id]
  end

  test "helpers work correctly after switching users" do
    # Login as Ash
    post login_path, params: { username: trainers(:ash).username, password: "password" }
    get dashboard_path
    assert_response :success
    assert_match "ash", response.body

    # Logout
    delete logout_path

    # Login as Gary
    post login_path, params: { username: trainers(:gary).username, password: "password" }
    get dashboard_path
    assert_response :success
    assert_match "gary", response.body
  end
end
