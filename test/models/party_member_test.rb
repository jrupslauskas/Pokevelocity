require "test_helper"

class PartyMemberTest < ActiveSupport::TestCase
  def setup
    @trainer = trainers(:ash)
    @pikachu = pokemons(:pikachu)
    @raichu = pokemons(:raichu)

    # Ensure trainer has captured these pokemon
    @trainer.captures.create!(pokemon: @pikachu, ball_type: "pokeball")
    @trainer.captures.create!(pokemon: @raichu, ball_type: "pokeball")
  end

  test "valid party member" do
    party_member = PartyMember.new(
      trainer: @trainer,
      pokemon: @pikachu,
      position: 1
    )
    assert party_member.valid?
  end

  test "position must be present" do
    party_member = PartyMember.new(
      trainer: @trainer,
      pokemon: @pikachu,
      position: nil
    )
    assert_not party_member.valid?
    assert_includes party_member.errors[:position], "can't be blank"
  end

  test "position must be between 1 and 6" do
    party_member = PartyMember.new(
      trainer: @trainer,
      pokemon: @pikachu,
      position: 0
    )
    assert_not party_member.valid?

    party_member.position = 7
    assert_not party_member.valid?

    party_member.position = 1
    assert party_member.valid?

    party_member.position = 6
    assert party_member.valid?
  end

  test "trainer can only have one pokemon per position" do
    PartyMember.create!(
      trainer: @trainer,
      pokemon: @pikachu,
      position: 1
    )

    duplicate_position = PartyMember.new(
      trainer: @trainer,
      pokemon: @raichu,
      position: 1
    )
    assert_not duplicate_position.valid?
    assert_includes duplicate_position.errors[:trainer_id], "already has a Pokémon in this position"
  end

  test "trainer cannot have same pokemon in multiple positions" do
    PartyMember.create!(
      trainer: @trainer,
      pokemon: @pikachu,
      position: 1
    )

    duplicate_pokemon = PartyMember.new(
      trainer: @trainer,
      pokemon: @pikachu,
      position: 2
    )
    assert_not duplicate_pokemon.valid?
    assert_includes duplicate_pokemon.errors[:pokemon_id], "is already in your party"
  end

  test "different trainers can have same pokemon in same position" do
    other_trainer = Trainer.create!(
      username: "gary_test_#{Time.now.to_i}",
      password: "password",
      icon_pokemon: @pikachu
    )
    other_trainer.captures.create!(pokemon: @pikachu, ball_type: "pokeball")

    PartyMember.create!(
      trainer: @trainer,
      pokemon: @pikachu,
      position: 1
    )

    other_party_member = PartyMember.new(
      trainer: other_trainer,
      pokemon: @pikachu,
      position: 1
    )
    assert other_party_member.valid?
  end

  test "trainer must have caught pokemon before adding to party" do
    uncaught_pokemon = Pokemon.create!(
      name: "Voltorb",
      pokedex_number: 100,
      difficulty: 2
    )

    party_member = PartyMember.new(
      trainer: @trainer,
      pokemon: uncaught_pokemon,
      position: 1
    )
    assert_not party_member.valid?
    assert_includes party_member.errors[:pokemon], "must be caught before adding to party"
  end

  test "party members are ordered by position" do
    PartyMember.create!(trainer: @trainer, pokemon: @pikachu, position: 3)
    PartyMember.create!(trainer: @trainer, pokemon: @raichu, position: 1)

    party_members = @trainer.party_members
    assert_equal 1, party_members.first.position
    assert_equal 3, party_members.last.position
  end
end
