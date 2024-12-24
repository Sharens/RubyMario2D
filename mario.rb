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
    @gui_elements = []
    reset_game
  end

  def reset_game
    # Usuń stare elementy
    @gui_elements.each(&:remove)
    @gui_elements.clear
    @player&.remove_sprite
    @goal&.remove_sprite
    @coins&.each(&:remove_sprite)
    @platforms&.each(&:remove_sprite)
    @enemies&.each(&:remove_sprite)
    
    # Utwórz nowe elementy
    @player = Player.new
    @platforms = []
    @coins = []
    @enemies = []
    @score = 0
    @lives = 3
    @score_text = Text.new(
      "Score: 0",
      x: 10, y: 10,
      size: 20,
      color: 'white'
    )
    @lives_text = Text.new(
      "Lives: 3",
      x: 10, y: 40,
      size: 20,
      color: 'white'
    )
    @gui_elements << @score_text
    @gui_elements << @lives_text
    @game_over = false
    @game_won = false
    @goal = Goal.new(700, 200)
    
    create_level
  end

  def create_level
    create_ground_with_gaps
    create_platforms
    create_coins
    create_enemies
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

  def create_coins
    # Monety na drodze
    add_coin(250, 450)  # Nad pierwszą częścią podłoża
    add_coin(450, 450)  # Nad dziurą
    add_coin(300, 350)  # Nad pierwszą platformą
    add_coin(500, 250)  # Nad drugą platformą
    add_coin(700, 150)  # Nad celem
  end

  def create_enemies
    # Przeciwnicy na platformach
    add_enemy(200, 460, 300, 460)  # Na pierwszej części podłoża
    add_enemy(600, 460, 700, 460)  # Na drugiej części podłoża
    add_enemy(300, 360, 400, 360)  # Na pierwszej platformie
  end

  def add_enemy(x1, y1, x2, y2)
    @enemies << Enemy.new(x1, y1, x2, y2)
  end

  def add_coin(x, y)
    @coins << Coin.new(x, y)
  end

  def update
    if @game_over || @game_won
      reset_game if KEYS['p']
      return
    end
    
    @player.update(KEYS)
    @enemies.each(&:update)
    check_collisions
    check_coin_collection
    check_enemy_collisions
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

  def check_coin_collection
    @coins.each do |coin|
      if !coin.collected && @player.collides_with?(coin)
        collect_coin(coin)
      end
    end
  end

  def collect_coin(coin)
    coin.collect
    @score += 10
    @score_text.text = "Score: #{@score}"
  end

  def check_enemy_collisions
    @enemies.each do |enemy|
      if @player.collides_with?(enemy)
        if @player.velocity_y > 0 && @player.y < enemy.y
          # Zabicie przeciwnika (skok na głowę)
          enemy.kill
          @player.bounce
          @score += 50
          @score_text.text = "Score: #{@score}"
        else
          # Otrzymanie obrażeń
          lose_life
        end
      end
    end
    
    # Usuń zabitych przeciwników
    @enemies.reject!(&:dead)
  end

  def lose_life
    @lives -= 1
    @lives_text.text = "Lives: #{@lives}"
    
    if @lives <= 0
      @game_over = true
      show_message("Game Over!")
    else
      @player.reset_position
    end
  end

  def check_death
    if @player.y > Window.height
      @game_over = true
      show_message("Game Over!")
    end
  end

  def check_win
    if @player.collides_with?(@goal)
      @game_won = true
      @goal.collect
      show_message("Level Complete!")
    end
  end

  def show_message(text)
    @gui_elements << Text.new(
      text,
      x: 350, y: 250,
      size: 20,
      color: 'white'
    )
    if @game_over || @game_won
      @gui_elements << Text.new(
        "Final Score: #{@score}",
        x: 350, y: 280,
        size: 20,
        color: 'white'
      )
      @gui_elements << Text.new(
        "Press 'P' to play again",
        x: 350, y: 310,
        size: 20,
        color: 'white'
      )
    end
  end
end

class Goal
  attr_reader :x, :y, :width, :height

  def initialize(x, y)
    @x = x
    @y = y
    @width = 40
    @height = 30
    @collected = false
    
    @sprite = Rectangle.new(
      x: x, y: y,
      width: @width, height: @height,
      color: 'fuchsia'
    )
  end

  def collect
    @sprite.remove
  end

  def remove_sprite
    @sprite&.remove
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
    
    @sprite = Triangle.new(
      x1: @x, y1: @y + @height,           # lewy dolny róg
      x2: @x + @width, y2: @y + @height,  # prawy dolny róg
      x3: @x + (@width/2), y3: @y,        # środek góry
      color: 'blue'
    )
  end

  def update(keys)
    handle_input(keys)
    apply_physics
    update_sprite_position
  end

  def update_sprite_position
    @sprite.x1 = @x
    @sprite.y1 = @y + @height
    @sprite.x2 = @x + @width
    @sprite.y2 = @y + @height
    @sprite.x3 = @x + (@width/2)
    @sprite.y3 = @y
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

  def remove_sprite
    @sprite&.remove
  end

  def bounce
    @velocity_y = -12  # Odbicie po zabiciu przeciwnika
  end

  def reset_position
    @x = 50
    @y = 400
    @velocity_x = 0
    @velocity_y = 0
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

  def remove_sprite
    @sprite&.remove
  end
end

class Coin
  attr_reader :x, :y, :width, :height
  attr_accessor :collected

  def initialize(x, y)
    @x = x
    @y = y
    @width = 15
    @height = 15
    @collected = false
    
    @sprite = Square.new(
      x: x, y: y,
      size: @width,
      color: 'yellow'
    )
  end

  def collect
    @collected = true
    @sprite.remove
  end

  def remove_sprite
    @sprite&.remove
  end
end

class Enemy
  attr_reader :x, :y, :width, :height
  attr_accessor :dead

  def initialize(x1, y1, x2, y2)
    @x = x1
    @y = y1
    @width = 30
    @height = 30
    @x1 = x1
    @x2 = x2
    @y1 = y1
    @y2 = y2
    @speed = 2
    @direction = 1
    @dead = false
    
    @sprite = Rectangle.new(
      x: @x, y: @y,
      width: @width, height: @height,
      color: 'red'
    )
  end

  def update
    return if @dead
    
    @x += @speed * @direction
    
    if @direction > 0 && @x >= @x2
      @direction = -1
    elsif @direction < 0 && @x <= @x1
      @direction = 1
    end
    
    @sprite.x = @x
  end

  def kill
    @dead = true
    @sprite.remove
  end

  def remove_sprite
    @sprite&.remove
  end
end

game = Game.new

update do
  game.update
end

show 