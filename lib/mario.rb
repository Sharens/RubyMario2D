require 'ruby2d'
require_relative 'mario/game'
require_relative 'mario/config'
require_relative 'version'

module Mario
  class Application
    def self.start
      Config.setup
      game = Game.new
      
      update do
        game.update
      end

      show
    end
  end
end

Mario::Application.start 