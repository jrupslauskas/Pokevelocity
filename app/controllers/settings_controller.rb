class SettingsController < ApplicationController
  before_action :require_login

  def edit
    @trainer = current_trainer
    @all_pokemon = Pokemon.order(:pokedex_number).limit(151)
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

    if @trainer.save
      redirect_to edit_settings_path, notice: "Settings updated successfully!"
    else
      @all_pokemon = Pokemon.order(:pokedex_number).limit(151)
      render :edit, status: :unprocessable_entity
    end
  end
end
