require "application_system_test_case"

class PasswordToggleTest < ApplicationSystemTestCase
  # ================================================================================
  # LOGIN PAGE PASSWORD TOGGLE TESTS
  # ================================================================================

  test "login page should display password toggle button" do
    visit login_path

    # Password field should exist
    assert_selector "input#password-field[type='password']"

    # Toggle button should be visible
    assert_selector "button.password-toggle-btn"

    # Eye icon should be visible
    assert_selector ".password-toggle-icon", text: "👁️"
  end

  test "login page password toggle should reveal password when clicked" do
    visit login_path

    # Fill in password by ID
    password_field = find("input#password-field")
    password_field.set("mysecretpassword")

    # Password field should initially be type="password"
    assert_equal "password", password_field[:type]

    # Icon should show eye emoji
    icon = find(".password-toggle-icon")
    assert_equal "👁️", icon.text

    # Click toggle button
    find("button.password-toggle-btn").click

    # Password field should now be type="text"
    password_field = find("input#password-field")
    assert_equal "text", password_field[:type]

    # Icon should change to see-no-evil monkey
    icon = find(".password-toggle-icon")
    assert_equal "🙈", icon.text

    # Value should still be visible in the field
    assert_equal "mysecretpassword", password_field.value
  end

  test "login page password toggle should hide password when clicked twice" do
    visit login_path

    # Fill in password by ID
    password_field = find("input#password-field")
    password_field.set("testpassword")

    toggle_button = find("button.password-toggle-btn")

    # Click once to show
    toggle_button.click
    assert_equal "text", password_field[:type]
    assert_equal "🙈", find(".password-toggle-icon").text

    # Click again to hide
    toggle_button.click
    assert_equal "password", password_field[:type]
    assert_equal "👁️", find(".password-toggle-icon").text

    # Value should still be there
    assert_equal "testpassword", password_field.value
  end

  test "login page password toggle should maintain password value during toggle" do
    visit login_path

    # Fill in password
    test_password = "MyP@ssw0rd123!"
    password_field = find("input#password-field")
    password_field.set(test_password)

    toggle_button = find("button.password-toggle-btn")

    # Toggle multiple times
    3.times do
      toggle_button.click
      assert_equal test_password, password_field.value
      toggle_button.click
      assert_equal test_password, password_field.value
    end
  end

  test "login page should allow login with password visible" do
    visit login_path

    trainer = trainers(:ash)

    # Fill in credentials
    fill_in "Username", with: trainer.username
    find("input#password-field").set("password")

    # Show password
    find("button.password-toggle-btn").click

    # Submit form with password visible
    click_button "Continue Adventure"

    # Should successfully log in
    assert_current_path dashboard_path
  end

  # ================================================================================
  # REGISTRATION PAGE PASSWORD TOGGLE TESTS
  # ================================================================================

  test "registration page should display password toggle button" do
    visit new_trainer_path

    # Password field should exist
    assert_selector "input#password-field-register[type='password']"

    # Toggle button should be visible
    assert_selector "button.password-toggle-btn"

    # Eye icon should be visible
    assert_selector ".password-toggle-icon", text: "👁️"
  end

  test "registration page password toggle should reveal password when clicked" do
    visit new_trainer_path

    # Fill in password by ID
    password_field = find("input#password-field-register")
    password_field.set("newuserpassword")

    # Password field should initially be type="password"
    assert_equal "password", password_field[:type]

    # Icon should show eye emoji
    icon = find(".password-toggle-icon")
    assert_equal "👁️", icon.text

    # Click toggle button
    find("button.password-toggle-btn").click

    # Password field should now be type="text"
    password_field = find("input#password-field-register")
    assert_equal "text", password_field[:type]

    # Icon should change to see-no-evil monkey
    icon = find(".password-toggle-icon")
    assert_equal "🙈", icon.text

    # Value should still be visible
    assert_equal "newuserpassword", password_field.value
  end

  test "registration page password toggle should hide password when clicked twice" do
    visit new_trainer_path

    # Fill in password by ID
    password_field = find("input#password-field-register")
    password_field.set("registerpass")

    toggle_button = find("button.password-toggle-btn")

    # Click once to show
    toggle_button.click
    assert_equal "text", password_field[:type]
    assert_equal "🙈", find(".password-toggle-icon").text

    # Click again to hide
    toggle_button.click
    assert_equal "password", password_field[:type]
    assert_equal "👁️", find(".password-toggle-icon").text

    # Value should still be there
    assert_equal "registerpass", password_field.value
  end

  test "registration page password toggle should maintain password value during toggle" do
    visit new_trainer_path

    # Fill in password by ID
    test_password = "Str0ng!P@ss"
    password_field = find("input#password-field-register")
    password_field.set(test_password)

    toggle_button = find("button.password-toggle-btn")

    # Toggle multiple times
    3.times do
      toggle_button.click
      assert_equal test_password, password_field.value
      toggle_button.click
      assert_equal test_password, password_field.value
    end
  end

  test "registration page password can be toggled without interfering with form" do
    visit new_trainer_path

    password_field = find("input#password-field-register")
    password_field.set("password123")

    # Initially hidden
    assert_equal "password", password_field[:type]

    # Toggle to visible
    find("button.password-toggle-btn").click
    assert_equal "text", password_field[:type]
    assert_equal "password123", password_field.value

    # Toggle back to hidden
    find("button.password-toggle-btn").click
    assert_equal "password", password_field[:type]
    assert_equal "password123", password_field.value

    # Form elements should still be accessible
    assert_selector "input[name='trainer[username]']"
    assert_selector "input[name='activation_code']"
  end

  # ================================================================================
  # ACCESSIBILITY AND UX TESTS
  # ================================================================================

  test "password toggle button should have proper accessibility attributes" do
    visit login_path

    toggle_button = find("button.password-toggle-btn")

    # Should have type="button" to prevent form submission
    assert_equal "button", toggle_button[:type]

    # Should have aria-label for screen readers
    assert toggle_button["aria-label"].present?
    assert_equal "Toggle password visibility", toggle_button["aria-label"]
  end

  test "password toggle should not submit form when clicked" do
    visit login_path

    trainer = trainers(:ash)

    # Fill in only username (no password yet)
    fill_in "Username", with: trainer.username

    # Click password toggle button (should not submit form)
    find("button.password-toggle-btn").click

    # Should still be on login page
    assert_current_path login_path
  end

  test "password field should have proper styling with toggle button" do
    visit login_path

    # Wrapper should exist
    assert_selector ".password-input-wrapper"

    # Input should have password-input class
    assert_selector "input.password-input#password-field"

    # Toggle button should be positioned inside wrapper
    wrapper = find(".password-input-wrapper")
    toggle_btn = wrapper.find("button.password-toggle-btn")

    assert toggle_btn.present?
  end

  test "login and registration pages should have independent toggles" do
    # Visit login page
    visit login_path
    login_password_field = find("input#password-field")
    assert_equal "password-field", login_password_field[:id]

    # Visit registration page
    visit new_trainer_path
    register_password_field = find("input#password-field-register")
    assert_equal "password-field-register", register_password_field[:id]

    # IDs should be different to avoid conflicts
    assert_not_equal login_password_field[:id], register_password_field[:id]
  end
end
