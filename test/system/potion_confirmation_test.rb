require "application_system_test_case"

class PotionConfirmationTest < ApplicationSystemTestCase
  def setup
    @trainer = trainers(:ash)
    @trainer.update!(
      adventures_remaining: 5,
      adventures_allocated_at: 1.hour.ago
    )
    # Give trainer some potions
    @trainer.add_item(:potion, 2)
    @trainer.add_item(:super_potion, 1)
    @trainer.add_item(:hyper_potion, 1)

    # Login
    visit login_path
    fill_in "Username", with: @trainer.username
    find("input#password-field").set("password")
    click_button "Continue Adventure"

    # Navigate to catches page for all tests
    visit catches_path
  end

  test "should show confirmation modal when using potion" do

    # Click Use Potion button
    click_button "Use Potion (2)"

    # Modal should be visible
    assert_selector "#potionConfirmationModal", visible: true
    assert_text "Use a Potion to restore 3 adventures?"
    assert_text "Any adventures restored beyond the maximum of 10 will be lost."
  end

  test "should show confirmation modal when using super potion" do
    # Click Use Super Potion button
    click_button "Use Super Potion (1)"

    # Modal should be visible
    assert_selector "#potionConfirmationModal", visible: true
    assert_text "Use a Super Potion to restore 6 adventures?"
    assert_text "Any adventures restored beyond the maximum of 10 will be lost."
  end

  test "should show confirmation modal when using hyper potion" do
    # Click Use Hyper Potion button
    click_button "Use Hyper Potion (1)"

    # Modal should be visible
    assert_selector "#potionConfirmationModal", visible: true
    assert_text "Use a Hyper Potion to restore 10 adventures?"
    assert_text "Any adventures restored beyond the maximum of 10 will be lost."
  end

  test "should restore adventures when clicking Yes on potion confirmation" do
    initial_adventures = @trainer.reload.adventures_remaining
    initial_potion_count = @trainer.item_quantity(:potion)

    # Click Use Potion button
    click_button "Use Potion (2)"

    # Click Yes on confirmation
    click_button "Yes"

    # Should be redirected and show success message
    assert_text /Used Potion! Restored \+3 adventure/

    # Adventures should be increased
    @trainer.reload
    assert_equal initial_adventures + 3, @trainer.adventures_remaining
    assert_equal initial_potion_count - 1, @trainer.item_quantity(:potion)
  end

  test "should not restore adventures when clicking No on potion confirmation" do
    initial_adventures = @trainer.reload.adventures_remaining
    initial_potion_count = @trainer.item_quantity(:potion)

    # Click Use Potion button
    click_button "Use Potion (2)"

    # Click No on confirmation
    click_button "No"

    # Modal should be hidden
    assert_no_selector "#potionConfirmationModal", visible: true

    # Adventures and potion count should remain the same
    @trainer.reload
    assert_equal initial_adventures, @trainer.adventures_remaining
    assert_equal initial_potion_count, @trainer.item_quantity(:potion)
  end

  test "should close modal when clicking overlay" do
    # Click Use Potion button
    click_button "Use Potion (2)"

    # Modal should be visible
    assert_selector "#potionConfirmationModal", visible: true

    # Click the overlay (outside modal)
    find("#potionConfirmationModal .modal-overlay").click

    # Modal should be hidden
    assert_no_selector "#potionConfirmationModal", visible: true
  end

  test "should show correct potion name and restore amount for each potion type" do
    # Test Potion
    click_button "Use Potion (2)"
    assert_text "Use a Potion to restore 3 adventures?"
    click_button "No"

    # Test Super Potion
    click_button "Use Super Potion (1)"
    assert_text "Use a Super Potion to restore 6 adventures?"
    click_button "No"

    # Test Hyper Potion
    click_button "Use Hyper Potion (1)"
    assert_text "Use a Hyper Potion to restore 10 adventures?"
    click_button "No"
  end

  test "should update adventure count display after using potion" do
    # Check initial count
    assert_text "5 / 10"

    # Use potion
    click_button "Use Potion (2)"
    click_button "Yes"

    # Should show updated count
    assert_text "8 / 10"
  end

  test "should update potion quantity display after using potion" do
    # Check initial count shows 2 potions
    assert_text "Use Potion (2)"

    # Use one potion
    click_button "Use Potion (2)"
    click_button "Yes"

    # Wait for redirect
    assert_current_path catches_path

    # Should now show 1 potion
    assert_text "Use Potion (1)"
  end

  test "should hide potion button when last potion is used" do
    # Start fresh with only 1 potion
    @trainer.remove_item(:potion, @trainer.item_quantity(:potion))
    @trainer.remove_item(:super_potion, @trainer.item_quantity(:super_potion))
    @trainer.remove_item(:hyper_potion, @trainer.item_quantity(:hyper_potion))
    @trainer.add_item(:potion, 1)

    # Refresh the page to see updated inventory
    visit catches_path

    # Should show 1 potion button
    assert_text "Use Potion (1)"

    # Use the last potion
    click_button "Use Potion (1)"
    click_button "Yes"

    # Wait for redirect
    assert_current_path catches_path

    # Potion button should no longer be visible
    assert_no_text "Use Potion"
  end

  test "should show all three potion buttons when trainer has all types" do
    assert_text "Use Potion (2)"
    assert_text "Use Super Potion (1)"
    assert_text "Use Hyper Potion (1)"
  end

  test "should only show buttons for potions the trainer owns" do
    # Remove super and hyper potions
    @trainer.remove_item(:super_potion, @trainer.item_quantity(:super_potion))
    @trainer.remove_item(:hyper_potion, @trainer.item_quantity(:hyper_potion))

    # Refresh the page to see updated inventory
    visit catches_path

    # Should only show regular potion
    assert_text "Use Potion (2)"
    assert_no_text "Use Super Potion"
    assert_no_text "Use Hyper Potion"
  end
end
