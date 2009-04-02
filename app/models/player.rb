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

class Player < ActiveRecord::Base
  belongs_to :game
  belongs_to :user
  has_many :nodes
  has_many :edges
  has_many :cards
  has_many :exchanges

  acts_as_list :scope => :game, :column => "number"

  validates_uniqueness_of :user_id, :scope => [:game_id]

  delegate :login, :to => :user, :prefix => true
  delegate :start_game, :preparing?, :to => :game, :prefix => true
  validates_numericality_of :bricks, :grain, :ore, :wool, :lumber, :settlements, :cities, :roads, :points,
                            :visible_points, :hidden_points, :greater_than_or_equal_to => 0, :only_integer => true, :allow_nil => true
  validates_numericality_of :bricks_exchange_rate, :grain_exchange_rate, :lumber_exchange_rate,
                            :ore_exchange_rate, :wool_exchange_rate, :allow_nil => true,
                            :greater_than => 0, :only_integer => true

  before_destroy :game_preparing?
  before_save :sum_resources, :sum_points

  state_machine :initial => :preparing do
    event :start do
      transition :preparing => :ready
    end

    event :play do
      transition :ready => :playing
    end

    after_transition :on => :start do |player|
      player.game_start_game
    end
  end

  def rob_resource
    resource_type = ([:bricks] * bricks + [:lumber] * lumber + [:ore] * ore + [:grain] * grain + [:wool] * wool).rand
    self[resource_type] -= 1 if resource_type
    resource_type
  end

  protected

  def sum_resources
    return unless bricks and lumber and ore and grain and wool
    self.resources = bricks + lumber + ore + grain + wool
  end

  def sum_points
    return unless visible_points and hidden_points
    self.points = visible_points + hidden_points
  end
end
