module Mario
  module Level
    class Generator
      def initialize(game)
        @game = game
        @current_tool = :platform
        @elements = initialize_elements
        @gui_elements = []
        show_interface
      end

      private

      def initialize_elements
        {
          platforms: [],
          coins: [],
          enemies: [],
          player: nil,
          goal: nil
        }
      end

      # ... reszta metod z oryginalnej klasy LevelGenerator
    end
  end
end 