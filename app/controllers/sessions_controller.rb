class SessionsController < ApplicationController
  def new
    # Render login form (homepage)
  end

  def create
    trainer = Trainer.find_by(username: params[:username])

    if trainer&.authenticate(params[:password])
      session[:trainer_id] = trainer.id
      redirect_to dashboard_path, notice: "Welcome back, #{trainer.username}!"
    else
      flash.now[:alert] = "Invalid username or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:trainer_id] = nil
    redirect_to root_path, notice: "You have been logged out"
  end
end
