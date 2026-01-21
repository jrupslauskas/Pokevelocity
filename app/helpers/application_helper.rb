module ApplicationHelper
  # Display trainer username with Elite Trainer badge if applicable
  # @param trainer [Trainer] the trainer object
  # @return [String] HTML-safe string with username and badge
  def display_trainer_name(trainer)
    if trainer.elite_trainer_level > 0
      content_tag(:span, style: "display: inline-flex; align-items: center; gap: 4px; white-space: nowrap;") do
        trainer.username.html_safe +
        image_tag("icons/pokeball_shop.png", alt: "Elite", style: "width: 16px; height: 16px; image-rendering: pixelated;") +
        content_tag(:span, trainer.elite_trainer_level)
      end
    else
      trainer.username
    end
  end
end
