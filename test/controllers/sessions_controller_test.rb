require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  # ================================================================================
  # LOGIN FORM DISPLAY TESTS
  # ================================================================================

  test "should get login page" do
    get login_path
    assert_response :success
  end

  test "should display login form" do
    get login_path
    assert_select "form"
  end

  test "should not require authentication to view login page" do
    get login_path
    assert_response :success
  end

  # ================================================================================
  # SUCCESSFUL LOGIN TESTS
  # ================================================================================

  test "should login with valid username and password" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    assert_redirected_to dashboard_path
  end

  test "should set session trainer_id on successful login" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    assert_equal trainer.id, session[:trainer_id]
  end

  test "should show welcome message on successful login" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    assert_equal "Welcome back, #{trainer.username}!", flash[:notice]
  end

  test "should redirect to dashboard on successful login" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    assert_redirected_to dashboard_path
    follow_redirect!
    assert_response :success
  end

  # ================================================================================
  # FAILED LOGIN - INVALID USERNAME TESTS
  # ================================================================================

  test "should not login with non-existent username" do
    post login_path, params: { username: "nonexistent", password: "password" }

    assert_response :unprocessable_entity
  end

  test "should not set session with invalid username" do
    post login_path, params: { username: "nonexistent", password: "password" }

    assert_nil session[:trainer_id]
  end

  test "should show error message for invalid username" do
    post login_path, params: { username: "nonexistent", password: "password" }

    assert_equal "Invalid username or password", flash[:alert]
  end

  test "should re-render login form after invalid username" do
    post login_path, params: { username: "nonexistent", password: "password" }

    assert_response :unprocessable_entity
    assert_select "form"
  end

  # ================================================================================
  # FAILED LOGIN - WRONG PASSWORD TESTS
  # ================================================================================

  test "should not login with wrong password" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "wrong_password" }

    assert_response :unprocessable_entity
  end

  test "should not set session with wrong password" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "wrong_password" }

    assert_nil session[:trainer_id]
  end

  test "should show error message for wrong password" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "wrong_password" }

    assert_equal "Invalid username or password", flash[:alert]
  end

  test "should re-render login form after wrong password" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "wrong_password" }

    assert_response :unprocessable_entity
    assert_select "form"
  end

  # ================================================================================
  # FAILED LOGIN - EMPTY FIELDS TESTS
  # ================================================================================

  test "should not login with empty username" do
    post login_path, params: { username: "", password: "password" }

    assert_response :unprocessable_entity
  end

  test "should not login with empty password" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "" }

    assert_response :unprocessable_entity
  end

  test "should not login with both fields empty" do
    post login_path, params: { username: "", password: "" }

    assert_response :unprocessable_entity
  end

  test "should not set session with empty credentials" do
    post login_path, params: { username: "", password: "" }

    assert_nil session[:trainer_id]
  end

  # ================================================================================
  # CASE SENSITIVITY TESTS
  # ================================================================================

  test "should not login with username in different case" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username.upcase, password: "password" }

    # Username lookup is case-sensitive by default
    # If ash is lowercase, ASH won't match
    if trainer.username != trainer.username.upcase
      assert_response :unprocessable_entity
      assert_nil session[:trainer_id]
    end
  end

  # ================================================================================
  # LOGOUT TESTS
  # ================================================================================

  test "should logout authenticated user" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    delete logout_path

    assert_redirected_to root_path
  end

  test "should clear session on logout" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }
    assert_equal trainer.id, session[:trainer_id]

    delete logout_path

    assert_nil session[:trainer_id]
  end

  test "should show logout message" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    delete logout_path

    assert_equal "You have been logged out", flash[:notice]
  end

  test "should redirect to root path after logout" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    delete logout_path

    assert_redirected_to root_path
  end

  test "should allow logout even when not logged in" do
    delete logout_path

    assert_redirected_to root_path
    assert_equal "You have been logged out", flash[:notice]
  end

  # ================================================================================
  # SESSION PERSISTENCE TESTS
  # ================================================================================

  test "should maintain session across requests" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    # Make another request
    get dashboard_path

    assert_response :success
    assert_equal trainer.id, session[:trainer_id]
  end

  test "should allow access to protected pages after login" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: "password" }

    get dashboard_path
    assert_response :success

    get pokedex_path
    assert_response :success

    get rewards_path
    assert_response :success
  end

  # ================================================================================
  # SECURITY TESTS
  # ================================================================================

  test "should not reveal whether username or password was wrong" do
    trainer = trainers(:ash)

    # Wrong username
    post login_path, params: { username: "nonexistent", password: "password" }
    wrong_username_message = flash[:alert]

    # Wrong password
    post login_path, params: { username: trainer.username, password: "wrong" }
    wrong_password_message = flash[:alert]

    # Both should have same generic message (security best practice)
    assert_equal wrong_username_message, wrong_password_message
    assert_equal "Invalid username or password", wrong_username_message
  end

  test "should not login with nil username" do
    post login_path, params: { username: nil, password: "password" }

    assert_response :unprocessable_entity
    assert_nil session[:trainer_id]
  end

  test "should not login with nil password" do
    trainer = trainers(:ash)
    post login_path, params: { username: trainer.username, password: nil }

    assert_response :unprocessable_entity
    assert_nil session[:trainer_id]
  end
end
