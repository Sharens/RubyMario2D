require 'ruby2d'

set title: "Super Mario Ruby", width: 800, height: 600

KEYS = {}

on :key_down do |event|
  KEYS[event.key] = true
end

on :key_up do |event|
  KEYS[event.key] = false
end

class Game
  def initialize
    @player = Player.new
    @platforms = []
    @game_over = false
    
    # Tworzenie podstawowego poziomu
    create_level
  end

  def create_level
    # Podłoże
    (0..7).each do |i|
      @platforms << Platform.new(i * 100, 500, 100, 20)
    end
    
    # Przeszkody i dziury
    @platforms << Platform.new(300, 400, 100, 20)
    @platforms << Platform.new(500, 300, 100, 20)
  end

  def update
    return if @game_over
    
    @player.update(KEYS)
    check_collisions
    check_death
  end

  def check_collisions
    @player.grounded = false
    
    @platforms.each do |platform|
      if @player.collides_with?(platform)
        @player.handle_collision(platform)
      end
    end
  end

  def check_death
    if @player.y > Window.height
      @game_over = true
      Text.new("Game Over!", x: 350, y: 250, size: 20)
    end
  end
end

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
    
    @sprite = Square.new(
      x: @x, y: @y,
      size: @width,
      color: 'red'
    )
  end

  def update(keys)
    handle_input(keys)
    apply_physics
    @sprite.x = @x
    @sprite.y = @y
  end

  def handle_input(keys)
    @velocity_x = 0
    @velocity_x -= 5 if keys['left']
    @velocity_x += 5 if keys['right']
    
    if keys['space'] && @grounded
      @velocity_y = -15
    end
  end

  def apply_physics
    # Grawitacja
    @velocity_y += 0.8 unless @grounded
    
    @x += @velocity_x
    @y += @velocity_y
  end

  def collides_with?(platform)
    @x < platform.x + platform.width &&
    @x + @width > platform.x &&
    @y < platform.y + platform.height &&
    @y + @height > platform.y
  end

  def handle_collision(platform)
    if @velocity_y > 0 && @y + @height - @velocity_y <= platform.y
      @y = platform.y - @height
      @velocity_y = 0
      @grounded = true
    end
  end
end

class Platform
  attr_reader :x, :y, :width, :height

  def initialize(x, y, width, height)
    @x = x
    @y = y
    @width = width
    @height = height
    
    @sprite = Rectangle.new(
      x: x, y: y,
      width: width, height: height,
      color: 'green'
    )
  end
end

game = Game.new

update do
  game.update
end

show 