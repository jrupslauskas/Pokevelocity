class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_trainer, :logged_in?

  private

  def current_trainer
    @current_trainer ||= Trainer.find_by(id: session[:trainer_id]) if session[:trainer_id]
  end

  def logged_in?
    current_trainer.present?
  end

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "You must be logged in to access this page"
    end
  end
end
