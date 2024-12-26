module Mario
  module Entities
    class Player
      attr_accessor :x, :y, :width, :height, :velocity_y, :grounded

      def initialize
        @x = 50
        @y = 400
        @width = 30
        @height = 30
        @velocity_x = 0
        @velocity_y = 0
        @grounded = false
        create_sprite
      end

      def update(keys)
        handle_input(keys)
        apply_physics
        update_sprite_position
      end

      private

      def create_sprite
        @sprite = Triangle.new(
          x1: @x, y1: @y + @height,
          x2: @x + @width, y2: @y + @height,
          x3: @x + (@width/2), y3: @y,
          color: 'blue'
        )
      end

      # ... reszta metod z oryginalnej klasy Player
    end
  end
end 