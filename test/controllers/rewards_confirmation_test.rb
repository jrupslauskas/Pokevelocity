require "test_helper"

class RewardsConfirmationTest < ActionDispatch::IntegrationTest
  def setup
    @trainer = trainers(:ash)
    post login_path, params: { username: @trainer.username, password: "password" }
  end

  test "rewards page should render without errors" do
    get rewards_path
    assert_response :success
  end

  test "rewards page should include confirmation modal HTML" do
    get rewards_path
    assert_response :success

    # Check for modal structure
    assert_select "#confirmationModal"
    assert_select ".modal-overlay"
    assert_select ".modal-content"
    assert_select "#confirmYes"
    assert_select "#confirmNo"
    assert_select "#storyPointsValue"
  end

  test "rewards page should have reward forms with data attributes" do
    get rewards_path
    assert_response :success

    # Check that forms have the reward-form class and data-story-points attribute
    assert_select "form.reward-form[data-story-points='1']"
    assert_select "form.reward-form[data-story-points='2']"
    assert_select "form.reward-form[data-story-points='3']"
    assert_select "form.reward-form[data-story-points='5']"
    assert_select "form.reward-form[data-story-points='8']"
  end

  test "rewards page should have reward-form-other class for custom input" do
    get rewards_path
    assert_response :success

    assert_select "form.reward-form-other"
    assert_select "#other-story-points"
  end

  test "rewards page should include turbo:load event listener for confirmation" do
    get rewards_path
    assert_response :success

    # Check that the JavaScript includes the turbo:load event
    assert_match /turbo:load/, response.body
    assert_match /confirmationModal/, response.body
    assert_match /reward-form/, response.body
  end

  test "submitting reward form should still award pokeball" do
    initial_pokeballs = @trainer.total_pokeballs

    post rewards_path, params: { story_points: 3 }

    # Should redirect with success message
    assert_redirected_to rewards_path
    follow_redirect!
    assert_match /Congratulations.*3 point/, flash[:notice]

    # Pokeballs should be awarded
    assert @trainer.reload.total_pokeballs > initial_pokeballs
  end

  test "submitting 1 point reward should award pokeball" do
    initial_pokeballs = @trainer.total_pokeballs

    post rewards_path, params: { story_points: 1 }

    assert_redirected_to rewards_path
    assert_match /1 point/, flash[:notice]
    assert @trainer.reload.total_pokeballs > initial_pokeballs
  end

  test "submitting 5 point reward should award pokeball" do
    initial_pokeballs = @trainer.total_pokeballs

    post rewards_path, params: { story_points: 5 }

    assert_redirected_to rewards_path
    assert_match /5 point/, flash[:notice]
    assert @trainer.reload.total_pokeballs > initial_pokeballs
  end

  test "submitting 8 point reward should award pokeball" do
    initial_pokeballs = @trainer.total_pokeballs

    post rewards_path, params: { story_points: 8 }

    assert_redirected_to rewards_path
    assert_match /8 point/, flash[:notice]
    assert @trainer.reload.total_pokeballs > initial_pokeballs
  end

  test "submitting custom story points should award pokeball" do
    initial_pokeballs = @trainer.total_pokeballs

    post rewards_path, params: { story_points: 13 }

    assert_redirected_to rewards_path
    assert_match /13 point/, flash[:notice]
    assert @trainer.reload.total_pokeballs > initial_pokeballs
  end

  test "submitting invalid story points should show error" do
    post rewards_path, params: { story_points: 0 }

    assert_redirected_to rewards_path
    assert_match /valid story point/, flash[:alert]
  end

  test "submitting negative story points should show error" do
    post rewards_path, params: { story_points: -5 }

    assert_redirected_to rewards_path
    assert_match /valid story point/, flash[:alert]
  end

  test "modal should have correct CSS classes" do
    get rewards_path
    assert_response :success

    # Check for modal CSS classes
    assert_select ".modal"
    assert_select ".modal-overlay"
    assert_select ".modal-content"
    assert_select ".modal-title"
    assert_select ".modal-message"
    assert_select ".modal-actions"
  end

  test "modal buttons should have correct classes" do
    get rewards_path
    assert_response :success

    # Check for button classes
    assert_select ".modal-actions .btn-primary", text: "Yes"
    assert_select ".modal-actions .btn-secondary", text: "No"
  end

  test "confirmation modal should be initially hidden" do
    get rewards_path
    assert_response :success

    # Modal should have display: none in inline style
    assert_select "#confirmationModal[style*='display: none']"
  end

  test "all story point buttons should be present" do
    get rewards_path
    assert_response :success

    assert_select "input[type='submit'][value='1 Point']"
    assert_select "input[type='submit'][value='2 Points']"
    assert_select "input[type='submit'][value='3 Points']"
    assert_select "input[type='submit'][value='5 Points']"
    assert_select "input[type='submit'][value='8 Points']"
    assert_select "input[type='submit'][value='Claim']"
  end

  test "JavaScript should prevent default form submission" do
    get rewards_path
    assert_response :success

    # Check that event listener prevents default
    assert_match /e\.preventDefault\(\)/, response.body
  end

  test "JavaScript should show modal on form submit" do
    get rewards_path
    assert_response :success

    # Check that modal is shown on form submit
    assert_match /modal\.style\.display = 'flex'/, response.body
  end

  test "JavaScript should handle Yes button click" do
    get rewards_path
    assert_response :success

    # Check for Yes button handler
    assert_match /confirmYes\.addEventListener/, response.body
    assert_match /nativeForm\.submit/, response.body
  end

  test "JavaScript should handle No button click" do
    get rewards_path
    assert_response :success

    # Check for No button handler
    assert_match /confirmNo\.addEventListener/, response.body
    assert_match /pendingForm = null/, response.body
  end

  test "JavaScript should close modal on overlay click" do
    get rewards_path
    assert_response :success

    # Check for overlay click handler
    assert_match /modal-overlay.*addEventListener/, response.body
  end
end
