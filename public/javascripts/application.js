// Pioneers - web game based on the Settlers of Catan board game.

// Copyright (C) 2009 Jakub Kuźma <qoobaa@gmail.com>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

var Pioneers = Pioneers || {};

Pioneers.initGame = function(gameId) {
  $.getJSON("/games/" + gameId + ".json",
            function(data) {
              Pioneers.game = new Pioneers.Game(data.game);
              //Pioneers.periodicallyUpdate(gameId);
            }
           );
};

Pioneers.updateGame = function(gameId) {
  $.getJSON("/games/" + gameId + ".json",
            function(data) {
              Pioneers.game.update(data.game);
            }
           );
};

Pioneers.periodicallyUpdate = function(gameId, interval) {
  Pioneers.timerId = setInterval(
    function() {
      Pioneers.updateGame(gameId);
    }, interval || 5000);
};

$.widget("ui.resourceField", {
           _init: function() {
             var widget = this;
             $("<a href='' class='minus'>-</a>").appendTo(this.element).click(
               function() {
                 widget.decreaseValue();
                 return false;
               }
             );
             $("<span class='value'></span>").appendTo(this.element);
             $("<a href='' class='plus'>+</a>").appendTo(this.element).click(
               function() {
                 widget.increaseValue();
                 return false;
               }
             );
             this._showValue();
           },

           _showValue: function() {
             var value = this.getValue();
             var valueElement = this.element.children(".value").text(Math.abs(value));
             valueElement.removeClass().addClass("value");
             if(value > 0) valueElement.addClass("positive");
             else if(value < 0) valueElement.addClass("negative");
           },

           increaseValue: function() {
             if(this.getValue() >= 0) this.setValue(this.getValue() + 1);
             else this.setValue(this.getValue() + this.getStep());
           },

           decreaseValue: function() {
             if(this.getValue() > 0) this.setValue(this.getValue() - 1);
             else if(this.getValue() - this.getStep() >= this.getMin()) this.setValue(this.getValue() - this.getStep());
           },

           setValue: function(value) {
             this._setData("value", value);
             this._showValue();
             this._trigger("change", value);
           },

           getValue: function() {
             return this._getData("value");
           },

           getMin: function() {
             return this._getData("min");
           },

           setMin: function(min) {
             this._setData("min", min);
             this.reset();
           },

           getStep: function() {
             return this._getData("step");
           },

           setStep: function(step) {
             this._setData("step", step);
             this.reset();
           },

           reset: function() {
             this.setValue(0);
           }
         }
        );

$.extend($.ui.resourceField, {
           getter: "getValue getMin getStep",
           setter: "setValue setMin setStep",
           defaults: {
             value: 0,
             step: 4,
             min: 0
           }
         }
        );

$(function() {
    Pioneers.initGame(10);
    $("#offer_bricks").resourceField({step: 1});
    $("#offer_grain").resourceField({step: 1});
    $("#offer_lumber").resourceField({step: 1});
    $("#offer_ore").resourceField({step: 1});
    $("#offer_wool").resourceField({step: 1});
    $("#exchange_bricks").resourceField();
    $("#exchange_grain").resourceField();
    $("#exchange_lumber").resourceField();
    $("#exchange_ore").resourceField();
    $("#exchange_wool").resourceField();
    $("#menu").tabs();
    $("#build .road").click(
      function() {
        $("#board").board("buildRoadMode", 1);
        return false;
      }
    );
    $("#build .settlement").click(
      function() {
        $("#board").board("buildSettlementMode", 1);
        return false;
      }
    );
    $("#build .city").click(
      function() {
        $("#board").board("buildCityMode", 1);
        return false;
      }
    );
    $("#build .cancel").click(
      function() {
        $("#board").board("defaultMode");
        return false;
      }
    );
  }
 );
