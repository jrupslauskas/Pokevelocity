require "net/http"
require "json"

namespace :pokemon do
  desc "Seed the 151 original Pokemon from PokeAPI"
  task seed: :environment do
    puts "Fetching 151 original Pokemon from PokeAPI..."

    (1..151).each do |pokedex_number|
      # Skip if already exists
      if Pokemon.exists?(pokedex_number: pokedex_number)
        puts "  Pokemon ##{pokedex_number} already exists, skipping..."
        next
      end

      begin
        # Fetch Pokemon data from PokeAPI
        uri = URI("https://pokeapi.co/api/v2/pokemon/#{pokedex_number}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)

        unless response.is_a?(Net::HTTPSuccess)
          puts "  Error fetching Pokemon ##{pokedex_number}: #{response.code}"
          next
        end

        data = JSON.parse(response.body)
        name = data["name"].capitalize

        # Get the official artwork (high quality) or front sprite
        image_url = data.dig("sprites", "other", "official-artwork", "front_default") ||
                    data.dig("sprites", "front_default")

        unless image_url
          puts "  No image found for #{name} (##{pokedex_number}), skipping..."
          next
        end

        # Download the image
        image_uri = URI(image_url)
        http_img = Net::HTTP.new(image_uri.host, image_uri.port)
        http_img.use_ssl = true
        http_img.verify_mode = OpenSSL::SSL::VERIFY_NONE

        image_request = Net::HTTP::Get.new(image_uri.request_uri)
        image_response = http_img.request(image_request)
        image_data = image_response.body

        # Create Pokemon with attached image
        pokemon = Pokemon.new(
          pokedex_number: pokedex_number,
          name: name
        )

        # Attach the image
        filename = "#{pokedex_number}_#{name.downcase}.png"
        pokemon.image.attach(
          io: StringIO.new(image_data),
          filename: filename,
          content_type: "image/png"
        )

        if pokemon.save
          puts "  ✓ Created #{name} (##{pokedex_number})"
        else
          puts "  ✗ Failed to create #{name}: #{pokemon.errors.full_messages.join(', ')}"
        end

        # Be nice to the API - small delay between requests
        sleep(0.1)

      rescue StandardError => e
        puts "  ✗ Error processing Pokemon ##{pokedex_number}: #{e.message}"
      end
    end

    puts "\nDone! #{Pokemon.count} Pokemon in database."
  end

  desc "Clear all Pokemon from database"
  task clear: :environment do
    count = Pokemon.count
    Pokemon.destroy_all
    puts "Removed #{count} Pokemon from database."
  end
end
