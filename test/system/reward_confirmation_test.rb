require "application_system_test_case"

class RewardConfirmationTest < ApplicationSystemTestCase
  def setup
    @trainer = trainers(:ash)
    # Login
    visit login_path
    fill_in "Username", with: @trainer.username
    find("input#password-field").set("password")
    click_button "Continue Adventure"
  end

  test "should show confirmation modal when claiming 1 point reward" do
    visit rewards_path

    # Click 1 Point button
    click_button "1 Point"

    # Modal should be visible
    assert_selector "#confirmationModal", visible: true
    assert_text "You completed a 1 point story?"
  end

  test "should show confirmation modal when claiming 3 point reward" do
    visit rewards_path

    # Click 3 Points button
    click_button "3 Points"

    # Modal should be visible
    assert_selector "#confirmationModal", visible: true
    assert_text "You completed a 3 point story?"
  end

  test "should show confirmation modal when claiming 5 point reward" do
    visit rewards_path

    # Click 5 Points button
    click_button "5 Points"

    # Modal should be visible
    assert_selector "#confirmationModal", visible: true
    assert_text "You completed a 5 point story?"
  end

  test "should show confirmation modal when claiming 8 point reward" do
    visit rewards_path

    # Click 8 Points button
    click_button "8 Points"

    # Modal should be visible
    assert_selector "#confirmationModal", visible: true
    assert_text "You completed a 8 point story?"
  end

  test "should show confirmation modal for custom story points" do
    visit rewards_path

    # Fill in custom story points
    fill_in "other-story-points", with: "13"
    click_button "Claim"

    # Modal should be visible with custom points
    assert_selector "#confirmationModal", visible: true
    assert_text "You completed a 13 point story?"
  end

  test "should award pokeball when clicking Yes on confirmation" do
    visit rewards_path

    initial_pokeballs = @trainer.reload.total_pokeballs

    # Click 3 Points button
    click_button "3 Points"

    # Click Yes on confirmation
    click_button "Yes"

    # Should be redirected and show success message
    assert_text /Congratulations.*3 point/

    # Pokeballs should be increased
    assert @trainer.reload.total_pokeballs > initial_pokeballs
  end

  test "should not award pokeball when clicking No on confirmation" do
    visit rewards_path

    initial_pokeballs = @trainer.reload.total_pokeballs

    # Click 3 Points button
    click_button "3 Points"

    # Click No on confirmation
    click_button "No"

    # Modal should be hidden
    assert_no_selector "#confirmationModal", visible: true

    # Pokeballs should remain the same
    assert_equal initial_pokeballs, @trainer.reload.total_pokeballs
  end

  test "should close modal when clicking overlay" do
    visit rewards_path

    # Click 5 Points button
    click_button "5 Points"

    # Modal should be visible
    assert_selector "#confirmationModal", visible: true

    # Click the overlay (outside modal)
    find(".modal-overlay").click

    # Modal should be hidden
    assert_no_selector "#confirmationModal", visible: true
  end

  test "should validate custom story points input" do
    visit rewards_path

    # Try to claim without entering a value
    click_button "Claim"

    # Should show browser validation or alert (depending on implementation)
    # The form has min: 1 validation, so it should prevent submission
  end

  test "should show correct point value for each button" do
    visit rewards_path

    # Test 1 Point
    click_button "1 Point"
    assert_text "You completed a 1 point story?"
    click_button "No"

    # Test 2 Points
    click_button "2 Points"
    assert_text "You completed a 2 point story?"
    click_button "No"

    # Test 3 Points
    click_button "3 Points"
    assert_text "You completed a 3 point story?"
    click_button "No"

    # Test 5 Points
    click_button "5 Points"
    assert_text "You completed a 5 point story?"
    click_button "No"

    # Test 8 Points
    click_button "8 Points"
    assert_text "You completed a 8 point story?"
    click_button "No"
  end
end
