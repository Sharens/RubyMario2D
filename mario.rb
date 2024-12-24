require 'ruby2d'
require 'json'

# Upewnij się, że katalog levels istnieje
Dir.mkdir('levels') unless Dir.exist?('levels')

set title: "Super Mario Ruby", width: 800, height: 600

# Inicjalizacja globalnej tablicy klawiszy
KEYS = {}

# Obsługa klawiszy
on :key_down do |event|
  KEYS[event.key] = true
end

on :key_up do |event|
  KEYS[event.key] = false
end

class Menu
  def initialize(game)
    @game = game
    @current_option = 0
    @options = ['Start Game', 'Load Level', 'Exit']
    @can_move = true
    create_menu_items
  end

  def create_menu_items
    @title = Text.new(
      'Super Mario Ruby',
      x: 300, y: 100,
      size: 30,
      color: 'white'
    )

    @menu_items = @options.map.with_index do |option, index|
      Text.new(
        option,
        x: 350,
        y: 250 + (index * 50),
        size: 20,
        color: index == @current_option ? 'yellow' : 'white'
      )
    end
  end

  def update
    if KEYS['up'] && @can_move
      move_cursor_up
      @can_move = false
    elsif KEYS['down'] && @can_move
      move_cursor_down
      @can_move = false
    elsif KEYS['return'] && @can_move
      select_option
      @can_move = false
    elsif !KEYS['up'] && !KEYS['down'] && !KEYS['return']
      @can_move = true
    end
  end

  def move_cursor_up
    @menu_items[@current_option].color = 'white'
    @current_option = (@current_option - 1) % @options.length
    @menu_items[@current_option].color = 'yellow'
  end

  def move_cursor_down
    @menu_items[@current_option].color = 'white'
    @current_option = (@current_option + 1) % @options.length
    @menu_items[@current_option].color = 'yellow'
  end

  def select_option
    case @current_option
    when 0 # Start Game
      hide_menu
      @game.start_game
    when 1 # Load Level
      hide_menu
      @game.load_custom_level
    when 2 # Exit
      Window.close
    end
  end

  def hide_menu
    @title.remove
    @menu_items.each(&:remove)
  end

  def show_menu
    create_menu_items
  end
end

class Game
  def initialize
    @gui_elements = []
    @current_level = 1
    @state = :menu
    @menu = Menu.new(self)
  end

  def start_game
    @state = :playing
    reset_game
  end

  def load_custom_level
    @state = :level_select
    show_level_input
  end

  def show_level_input
    @gui_elements.each(&:remove)
    @gui_elements.clear
    
    @level_prompt = Text.new(
      "Enter level number (1-9) and press Enter:",
      x: 250, y: 250,
      size: 20,
      color: 'white'
    )
    @gui_elements << @level_prompt
  end

  def update
    case @state
    when :menu
      @menu.update
    when :level_select
      handle_level_selection
    when :playing
      if @game_over || @game_won
        if KEYS['p']
          clean_up_game
          @state = :menu
          @menu.show_menu
        else
          reset_game if KEYS['r']
        end
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
  end

  def clean_up_game
    # Usuń wszystkie elementy GUI
    @gui_elements.each(&:remove)
    @gui_elements.clear
    
    # Usuń wszystkie elementy gry
    @player&.remove_sprite
    @goal&.remove_sprite
    @coins&.each(&:remove_sprite)
    @platforms&.each(&:remove_sprite)
    @enemies&.each(&:remove_sprite)
    
    # Wyczyść kolekcje
    @coins = []
    @platforms = []
    @enemies = []
  end

  def reset_game
    clean_up_game
    
    # Utwórz nowe elementy
    @player = Player.new
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
    
    load_level(@current_level)
  end

  def handle_level_selection
    ('1'..'9').each do |num|
      if KEYS[num]
        @current_level = num.to_i
        @state = :playing
        reset_game
        break
      end
    end
    
    if KEYS['escape']
      @state = :menu
      @gui_elements.each(&:remove)
      @gui_elements.clear
      @menu.show_menu
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
        "Press 'R' to retry or 'P' for menu",
        x: 350, y: 310,
        size: 20,
        color: 'white'
      )
    end
  end

  def load_level(level_number)
    level_file = File.read("levels/level#{level_number}.txt")
    level_data = JSON.parse(level_file)
    
    # Wczytaj pozycję gracza
    @player.x = level_data['player']['x']
    @player.y = level_data['player']['y']
    
    # Wczytaj cel
    goal_data = level_data['goal']
    @goal = Goal.new(goal_data['x'], goal_data['y'])
    
    # Wczytaj platformy
    level_data['platforms'].each do |platform|
      @platforms << Platform.new(
        platform['x'],
        platform['y'],
        platform['width'],
        platform['height']
      )
    end
    
    # Wczytaj monety
    level_data['coins'].each do |coin|
      add_coin(coin['x'], coin['y'])
    end
    
    # Wczytaj przeciwników
    level_data['enemies'].each do |enemy|
      add_enemy(
        enemy['x1'],
        enemy['y1'],
        enemy['x2'],
        enemy['y2']
      )
    end
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