class SettingsController < ApplicationController
  before_action :require_login

  def edit
    @trainer = current_trainer
    @all_pokemon = Pokemon.order(:pokedex_number).limit(151)
    @trainer_sprites = get_trainer_sprites
  end

  def update
    @trainer = current_trainer

    # Update icon based on whether pokemon or trainer sprite was selected
    if params[:icon_pokemon_id].present?
      @trainer.icon_pokemon_id = params[:icon_pokemon_id]
      @trainer.icon_trainer_sprite = nil
    elsif params[:icon_trainer_sprite].present?
      @trainer.icon_trainer_sprite = params[:icon_trainer_sprite]
      @trainer.icon_pokemon_id = nil
    end

    # Update gameplay preferences
    # Note: The hidden field ensures this parameter is always sent when submitting from Gameplay tab
    if params.key?(:show_encounter_animation)
      @trainer.show_encounter_animation = (params[:show_encounter_animation] == "1")
    end

    if params.key?(:play_pokecenter_audio)
      @trainer.play_pokecenter_audio = (params[:play_pokecenter_audio] == "1")
    end

    if @trainer.save
      redirect_to edit_settings_path, notice: "Settings updated successfully!"
    else
      @all_pokemon = Pokemon.order(:pokedex_number).limit(151)
      @trainer_sprites = get_trainer_sprites
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Get list of available trainer sprites, sorted alphabetically
  # This should match the sprites available during account creation
  def get_trainer_sprites
    regular_trainers = [
      "aroma-lady", "beauty", "biker", "bill", "bird-keeper", "black-belt",
      "blue-casual", "blue-faceoff", "bug-catcher", "burglar", "camper",
      "channeler", "cool-couple", "cooltrainer-female", "cooltrainer-male", "crush-girl",
      "crush-kin", "cue-ball", "daisy-oak", "engineer", "fisherman",
      "gentleman", "hiker", "juggler", "lady",
      "lass", "mr-fuji", "painter", "picnicker", "pokemaniac", "pokemon-breeder",
      "pokemon-ranger-female", "pokemon-ranger-male", "psychic-female", "psychic-male",
      "red-portrait", "rocker", "rocker-grunt-female", "rocker-grunt-male", "ruin-maniac",
      "sailor", "scientist", "sis-and-bro", "super-nerd", "swimmer-female", "swimmer-male",
      "tamer", "tuber", "twins", "young-couple", "youngster"
    ]

    gym_leaders = [
      "gymLeaders/agatha", "gymLeaders/blaine", "gymLeaders/blue", "gymLeaders/brock", "gymLeaders/bruno",
      "gymLeaders/erika", "gymLeaders/giovanni", "gymLeaders/koga", "gymLeaders/lance", "gymLeaders/lorelei",
      "gymLeaders/ltsurge", "gymLeaders/misty", "gymLeaders/oak", "gymLeaders/red", "gymLeaders/sabrina"
    ]

    # Sort alphabetically by display name (last part after '/')
    (regular_trainers + gym_leaders).sort_by { |sprite| sprite.split("/").last }
  end
end
