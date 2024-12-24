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
    @game_won = false
    @goal = Goal.new(700, 200) # Cel do zdobycia
    
    # Tworzenie poziomu
    create_level
  end

  def create_level
    # Podłoże z dziurami
    create_ground_with_gaps
    
    # Platformy i przeszkody
    create_platforms
  end

  def create_ground_with_gaps
    # Pierwsza część podłoża
    (0..3).each do |i|
      @platforms << Platform.new(i * 100, 500, 100, 20)
    end
    
    # Dziura
    
    # Druga część podłoża
    (5..7).each do |i|
      @platforms << Platform.new(i * 100, 500, 100, 20)
    end
  end

  def create_platforms
    # Platformy prowadzące do celu
    @platforms << Platform.new(300, 400, 100, 20)
    @platforms << Platform.new(500, 300, 100, 20)
    @platforms << Platform.new(700, 250, 100, 20) # Platforma pod celem
  end

  def update
    return if @game_over || @game_won
    
    @player.update(KEYS)
    check_collisions
    check_death
    check_win
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
      show_message("Game Over!", 'red')
    end
  end

  def check_win
    if @player.collides_with?(@goal)
      @game_won = true
      @goal.collect
      show_message("Level Complete!", 'green')
    end
  end

  def show_message(text, color)
    Text.new(
      text,
      x: 350, y: 250,
      size: 20,
      color: color
    )
  end
end

class Goal
  attr_reader :x, :y, :width, :height

  def initialize(x, y)
    @x = x
    @y = y
    @width = 30
    @height = 30
    @collected = false
    
    @sprite = Square.new(
      x: x, y: y,
      size: 30,
      color: 'yellow'
    )
  end

  def collect
    @sprite.remove
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
    @velocity_y += 0.8 unless @grounded
    
    @x += @velocity_x
    @y += @velocity_y
  end

  def collides_with?(object)
    @x < object.x + object.width &&
    @x + @width > object.x &&
    @y < object.y + object.height &&
    @y + @height > object.y
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