# -*- coding: utf-8 -*-

# Pioneers - web game based on the Settlers of Catan board game.
#
# Copyright (C) 2009 Jakub Kuźma <qoobaa@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'test_helper'

class GameTest < Test::Unit::TestCase
  should_have_many :players
  should_have_one :map

  context "In waiting_for_players phase" do
    setup do
      @game = Game.create!
    end

    should "not allow to start without players" do
      assert !@game.start!
      assert @game.errors.on(:players)
    end

    should "not allow to start without map" do
      assert !@game.start!
      assert @game.errors.on(:map)
    end

    should "not allow to start with one player" do
      @game.players << Factory(:player)
      assert !@game.start!
      assert @game.errors.on(:players)
    end

    should "not allow to start with two players" do
      2.times { @game.players << Factory(:player) }
      assert !@game.start!
      assert @game.errors.on(:players)
    end

    should "allow to start with map and three players" do
      3.times { @game.players << Factory(:player) }
      @game.map = Factory(:map)
      assert @game.start!
    end
  end

  context "In first_settlement phase of first player" do
    setup do
      @game = Game.create!
      3.times { @game.players << Factory(:player, :settlements => 5) }
      @game.map = Factory(:map, :hexes_attributes => [{ :hex_type => "forest", :roll => 2 }, { :hex_type => "forest", :roll => 2}, { :hex_type => "sea" }, { :hex_type => "sea" }], :size => [2, 2] )
      @game.current_player_number = 1
      @game.aasm_state = "first_settlement"
      @game.save!
    end

    should "allow to build first settlement by first player" do
      node = @game.map_nodes.build(:position => [0, 1])
      node.player = @game.players[0]
      assert node.valid?
    end

    should "not allow to build settlement by second player" do
      node = @game.map_nodes.build(:position => [0, 1])
      node.player = @game.players[1]
      assert !node.valid?
    end

    should "not allow to build second settlement by first player" do
      node = @game.map_nodes.build(:position => [0, 1])
      node.player = @game.players[0]
      node.save!
      node = @game.map_nodes.build(:position => [0, 3])
      node.player = @game.players[0]
      assert !node.valid?
    end

    should "not allow to build settlement on the sea" do
      node = @game.map_nodes.build(:position => [1, 5])
      node.player = @game.players[0]
      assert !node.valid?
    end

    should "add one point to first player after settlement is built" do
      node = @game.map_nodes.build(:position => [0, 1])
      node.player = @game.players[0]
      node.save!
      assert_equal 1, @game.players[0].points
    end

    should "not allow to build road by first player" do
      edge = @game.map_edges.build(:position => [0, 3])
      edge.player = @game.players[0]
      assert !edge.valid?
    end
  end

  context "In first_road phase of first player" do
    setup do
      @game = Game.create!
      3.times { @game.players << Factory(:player, :settlements => 5, :roads => 15) }
      @game.map = Factory(:map, :hexes_attributes => [{ :hex_type => "forest", :roll => 2 }, { :hex_type => "forest", :roll => 2}, { :hex_type => "sea" }, { :hex_type => "sea" }], :size => [2, 2] )
      @game.current_player_number = 1
      @game.aasm_state = "first_settlement"
      @game.save!
      node = @game.map_nodes.build(:position => [0, 1])
      node.player = @game.players[0]
      node.save!
      @game.aasm_state = "first_road"
      @game.save!
    end

    should "allow to build road near first settlement by first player" do
      edge = @game.map_edges.build(:position => [0, 3])
      edge.player = @game.players[0]
      assert edge.valid?
    end

    should "not allow to build road near first settlement by second player" do
      edge = @game.map_edges.build(:position => [0, 3])
      edge.player = @game.players[1]
      assert !edge.valid?
    end

    should "not allow to build road away from first settlement by first player" do
      edge = @game.map_edges.build(:position => [0, 5])
      edge.player = @game.players[0]
      assert !edge.valid?
    end
  end

  context "In second_settlement phase of first player with settlement [0, 3] and road [0, 7]" do
    setup do
      @game = Game.create!
      3.times { @game.players << Factory(:player, :settlements => 5, :roads => 15) }
      @game.map = Factory(:map, :hexes_attributes => [{ :hex_type => "desert" }, { :hex_type => "forest", :roll => 2}, { :hex_type => "sea" }, { :hex_type => "sea" }], :size => [2, 2] )
      @game.current_player_number = 1
      @game.aasm_state = "first_settlement"
      @game.save!
      node = @game.map_nodes.build(:position => [0, 3])
      node.player = @game.players[0]
      node.save!
      @game.aasm_state = "first_road"
      @game.save!
      edge = @game.map_edges.build(:position => [0, 7])
      edge.player = @game.players[0]
      edge.save!
      @game.aasm_state = "second_settlement"
      @game.save!
    end

    should "allow to build second settlement by first player" do
      node = @game.map_nodes.build(:position => [0, 1])
      node.player = @game.players[0]
      assert node.valid?
    end

    should "add nothing to player resources on [0, 1]" do
      node = @game.map_nodes.build(:position => [0, 1])
      node.player = @game.players[0]
      node.save!
      player = @game.players[0].reload
      assert_equal 0, player.bricks
      assert_equal 0, player.lumber
      assert_equal 0, player.ore
      assert_equal 0, player.grain
      assert_equal 0, player.wool
    end

    should "add nothing to player resources on [0, 5]" do
      node = @game.map_nodes.build(:position => [0, 5])
      node.player = @game.players[0]
      node.save!
      player = @game.players[0].reload
      assert_equal 0, player.bricks
      assert_equal 1, player.lumber
      assert_equal 0, player.ore
      assert_equal 0, player.grain
      assert_equal 0, player.wool
    end

    should "not allow to build settlement by second player" do
      node = @game.map_nodes.build(:position => [0, 1])
      node.player = @game.players[1]
      assert !node.valid?
    end

    should "not allow to build third settlement by first player" do
      node = @game.map_nodes.build(:position => [0, 1])
      node.player = @game.players[0]
      node.save!
      node = @game.map_nodes.build(:position => [0, 3])
      node.player = @game.players[0]
      assert !node.valid?
    end

    should "not allow to build settlement on the sea" do
      node = @game.map_nodes.build(:position => [1, 5])
      node.player = @game.players[0]
      assert !node.valid?
    end

    should "add one point to first player after settlement is built" do
      node = @game.map_nodes.build(:position => [0, 1])
      node.player = @game.players[0]
      node.save!
      assert_equal 2, @game.players[0].points
    end
  end

  context "In second_road phase of first player" do
    setup do
      @game = Game.create!
      3.times { @game.players << Factory(:player, :settlements => 5, :roads => 15) }
      @game.map = Factory(:map, :hexes_attributes => [{ :hex_type => "desert" }, { :hex_type => "forest", :roll => 2}, { :hex_type => "sea" }, { :hex_type => "sea" }], :size => [2, 2] )
      @game.current_player_number = 1
      @game.aasm_state = "first_settlement"
      @game.save!
      node = @game.map_nodes.build(:position => [0, 3])
      node.player = @game.players[0]
      node.save!
      @game.aasm_state = "first_road"
      @game.save!
      edge = @game.map_edges.build(:position => [0, 7])
      edge.player = @game.players[0]
      edge.save!
      @game.aasm_state = "second_settlement"
      @game.save!
      node = @game.map_nodes.build(:position => [0, 1])
      node.player = @game.players[0]
      node.save!
      @game.aasm_state = "second_road"
      @game.save!
    end

    should "not allow to build road near first settlement by first player" do
      edge = @game.map_edges.build(:position => [0, 6])
      edge.player = @game.players[0]
      assert !edge.valid?
    end

    should "not allow to build road near second settlement by second player" do
      edge = @game.map_edges.build(:position => [0, 3])
      edge.player = @game.players[1]
      assert !edge.valid?
    end

    should "not allow to build road away from first settlement by first player" do
      edge = @game.map_edges.build(:position => [1, 3])
      edge.player = @game.players[0]
      assert !edge.valid?
    end

    should "allow to build road near second settlement by first player" do
      edge = @game.map_edges.build(:position => [0, 3])
      edge.player = @game.players[0]
      assert edge.valid?
    end
  end

  context "In first_settlement phase of second player with settlement on [0, 1] and road on [0, 3]" do
    setup do
      @game = Game.create!
      3.times { @game.players << Factory(:player, :settlements => 5, :roads => 15) }
      @game.map = Factory(:map, :hexes_attributes => [{ :hex_type => "forest", :roll => 2 }, { :hex_type => "forest", :roll => 2}, { :hex_type => "sea" }, { :hex_type => "sea" }], :size => [2, 2] )
      @game.current_player_number = 1
      @game.aasm_state = "first_settlement"
      @game.save!
      node = @game.map_nodes.build(:position => [0, 1])
      node.player = @game.players[0]
      node.save!
      @game.aasm_state = "first_road"
      @game.save!
      edge = @game.map_edges.build(:position => [0, 3])
      edge.player = @game.players[0]
      edge.save!
      @game.current_player_number = 2
      @game.aasm_state = "first_settlement"
      @game.save!
    end

    should "not allow to build settlement by first player" do
      node = @game.map_nodes.build(:position => [0, 3])
      node.player = @game.players[0]
      assert !node.valid?
    end

    should "not allow to build settlement on the same position by second player" do
      node = @game.map_nodes.build(:position => [0, 1])
      node.player = @game.players[1]
      assert !node.valid?
    end

    should "not allow to build settlement too close to first settlement by second player" do
      node = @game.map_nodes.build(:position => [0, 2])
      node.player = @game.players[1]
      assert !node.valid?
    end

    should "allow to build settlement on correct position by second player" do
      node = @game.map_nodes.build(:position => [0, 3])
      node.player = @game.players[1]
      assert node.valid?
    end

    should "not allow to build second settlement by second player" do
      node = @game.map_nodes.build(:position => [0, 3])
      node.player = @game.players[1]
      node.save!
      node = @game.map_nodes.build(:position => [0, 5])
      node.player = @game.players[1]
      assert !node.valid?
    end
  end

  context "In after_roll phase of first player with settlement(player1) on [0, 1] and road(player1) on [0, 3], settlement(player2) on [1, 3]" do
    setup do
      @game = Game.create!
      3.times { @game.players << Factory(:player, :settlements => 5, :bricks => 5, :ore => 5, :wool => 5, :lumber => 5, :grain => 5, :cities => 5, :roads => 15) }
      @game.map = Factory(:map, :hexes_attributes => [{ :hex_type => "forest", :roll => 2 }, { :hex_type => "forest", :roll => 2}, { :hex_type => "sea" }, { :hex_type => "sea" }], :size => [2, 2] )
      @game.current_player_number = 1
      @game.aasm_state = "first_settlement"
      @game.save!
      node = @game.map_nodes.build(:position => [0, 1])
      node.player = @game.players[0]
      node.save!
      @game.aasm_state = "first_road"
      @game.save!
      edge = @game.map_edges.build(:position => [0, 3])
      edge.player = @game.players[0]
      edge.save!
      @game.aasm_state = "first_settlement"
      @game.current_player_number = 2
      @game.save!
      node = @game.map_nodes.build(:position => [1, 3])
      node.player = @game.players[1]
      node.save!
      @game.current_player_number = 1
      @game.aasm_state = "after_roll"
      @game.save!
    end

    should "not allow to build on position without road by first player" do
      node = @game.map_nodes.build(:position => [1, 1])
      node.player = @game.players[0]
      assert !node.valid?
    end

    should "allow to build on position with road by first player" do
      edge = @game.map_edges.build(:position => [1, 2])
      edge.player = @game.players[0]
      edge.save!
      node = @game.map_nodes.build(:position => [1, 1])
      node.player = @game.players[0]
      assert node.valid?
    end

    should "not allow to build settlement by second player" do
      node = @game.map_nodes.build(:position => [1, 1])
      node.player = @game.players[1]
      assert !node.valid?
    end

    should "not allow to build settlement without resources by first player" do
      @game.players[0].update_attributes(:bricks => 1)
      edge = @game.map_edges.build(:position => [1, 2])
      edge.player = @game.players[0]
      edge.save!
      node = @game.map_nodes.build(:position => [1, 1])
      node.player = @game.players[0]
      assert !node.valid?
    end

    should "not allow to build settlement without free settlements by first player" do
      @game.players[0].update_attributes(:settlements => 0)
      edge = @game.map_edges.build(:position => [1, 2])
      edge.player = @game.players[0]
      edge.save!
      node = @game.map_nodes.build(:position => [1, 1])
      node.player = @game.players[0]
      assert !node.valid?
    end

    should "allow to expand settlement to city by first player" do
      node = @game.players[0].nodes.first
      assert node.expand!
      assert node.valid?
    end

    should "add one victory point to first player after expansion" do
      node = @game.players[0].nodes.first
      node.expand
      node.save!
      @game.players[0].reload
      assert_equal 2, @game.players[0].points
    end

    should "not allow to expand settlement to city without resources by first player" do
      @game.players[0].update_attributes(:ore => 0)
      node = @game.players[0].nodes.first
      assert !node.expand!
      assert !node.valid?
    end

    should "not allow to expand settlement to city without cities by first player" do
      @game.players[0].update_attributes(:cities => 0)
      node = @game.players[0].nodes.first
      assert !node.expand!
      assert !node.valid?
    end

    should "not allow to expand settlement of second player" do
      node = @game.players[1].nodes.first
      assert !node.expand!
      assert !node.valid?
    end

    should "allow to build road near first settlement by first player" do
      edge = @game.map_edges.build(:position => [0, 4])
      edge.player = @game.players[0]
      assert edge.valid?
    end

    should "allow to build road near first road by first player" do
      edge = @game.map_edges.build(:position => [1, 2])
      edge.player = @game.players[0]
      assert edge.valid?
    end

    should "not allow to build road on not settleable edge by first player" do
      edge = @game.map_edges.build(:position => [0, 2])
      edge.player = @game.players[0]
      assert !edge.valid?
    end

    should "not allow to build road near first settlement of second player by first player" do
      edge = @game.map_edges.build(:position => [1, 5])
      edge.player = @game.players[0]
      assert !edge.valid?
    end

    should "not allow to build road if player has no resources by first player" do
      @game.players[0].update_attributes(:bricks => 0)
      edge = @game.map_edges.build(:position => [0, 4])
      edge.player = @game.players[0]
      assert !edge.valid?
    end

    should "not allow to build road if player has no roads by first player" do
      @game.players[0].update_attributes(:roads => 0)
      edge = @game.map_edges.build(:position => [0, 4])
      edge.player = @game.players[0]
      assert !edge.valid?
    end

    should "not allow to build road by second player" do
      edge = @game.map_edges.build(:position => [1, 5])
      edge.player = @game.players[1]
      assert !edge.valid?
    end

    should "not allow to build road through first settlement of second player by first player" do
      edge = @game.map_edges.build(:position => [1, 2])
      edge.player = @game.players[0]
      edge.save!
      edge = @game.map_edges.build(:position => [1, 4])
      edge.player = @game.players[0]
      edge.save!
      edge = @game.map_edges.build(:position => [1, 5])
      edge.player = @game.players[0]
      edge.save!
      edge = @game.map_edges.build(:position => [1, 7])
      edge.player = @game.players[0]
      assert !edge.valid?
    end
  end
end
