class RewardsController < ApplicationController
  before_action :require_login

  def index
    @trainer = current_trainer
  end

  def create
    @trainer = current_trainer
    story_points = params[:story_points].to_i

    if story_points > 0
      result = @trainer.award_pokeball_for_ticket(story_points)
      redirect_to rewards_path, notice: "Congratulations! You earned a #{result[:ball_type].humanize} for completing a #{story_points} point ticket!"
    else
      redirect_to rewards_path, alert: "Please enter a valid story point value"
    end
  end

  def buy_item
    @trainer = current_trainer
    item_key = params[:item_key]
    item = Item.find_by(key: item_key)

    if item.nil?
      redirect_to rewards_path, alert: "Item not found"
      return
    end

    if item.buy_price.nil?
      redirect_to rewards_path, alert: "This item cannot be purchased"
      return
    end

    if @trainer.currency < item.buy_price
      redirect_to rewards_path, alert: "Not enough currency! You need #{item.buy_price} but only have #{@trainer.currency}"
      return
    end

    @trainer.currency -= item.buy_price
    @trainer.add_item(item_key, 1)
    @trainer.save

    redirect_to rewards_path, notice: "Successfully purchased #{item.name} for #{item.buy_price} currency!"
  end

  def sell_item
    @trainer = current_trainer
    item_key = params[:item_key]
    item = Item.find_by(key: item_key)

    if item.nil?
      redirect_to rewards_path, alert: "Item not found"
      return
    end

    if item.sell_price.nil?
      redirect_to rewards_path, alert: "This item cannot be sold"
      return
    end

    unless @trainer.has_item?(item_key, 1)
      redirect_to rewards_path, alert: "You don't have any #{item.name} to sell"
      return
    end

    @trainer.currency += item.sell_price
    @trainer.remove_item(item_key, 1)
    @trainer.save

    redirect_to rewards_path, notice: "Successfully sold #{item.name} for #{item.sell_price} currency!"
  end
end
