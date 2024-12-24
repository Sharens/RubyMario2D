require 'ruby2d'
require 'json'

# Użyj zmiennej globalnej zamiast stałej
$mouse_handler = nil

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

# Upewnij się, że katalog levels istnieje
Dir.mkdir('levels') unless Dir.exist?('levels')

on :mouse_down do |event|
  if $mouse_handler
    if event.button == :left
      $mouse_handler.call(event.x, event.y, :add)
    elsif event.button == :right
      $mouse_handler.call(event.x, event.y, :remove)
    end
  end
end

class Menu
  def initialize(game)
    @game = game
    @current_option = 0
    @options = ['Start Game', 'Load Level', 'Create Level', 'Exit']
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
    when 2 # Create Level
      hide_menu
      @game.start_level_generator
    when 3 # Exit
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

class LevelGenerator
  def initialize(game)
    @game = game
    @current_tool = :platform
    @elements = {
      platforms: [],
      coins: [],
      enemies: [],
      player: nil,
      goal: nil
    }
    @gui_elements = []
    @mouse_pressed = false
    show_interface
  end

  def show_interface
    @gui_elements << Text.new(
      "Level Generator - Controls:",
      x: 10, y: 10,
      size: 20,
      color: 'white'
    )
    @gui_elements << Text.new(
      "1: Platform | 2: Coin | 3: Enemy | 4: Player | 5: Goal",
      x: 10, y: 40,
      size: 16,
      color: 'white'
    )
    @gui_elements << Text.new(
      "Left Click: Place | Right Click: Remove | S: Save | ESC: Menu",
      x: 10, y: 70,
      size: 16,
      color: 'white'
    )
    @current_tool_text = Text.new(
      "Current Tool: Platform",
      x: 10, y: 100,
      size: 16,
      color: 'yellow'
    )
    @gui_elements << @current_tool_text
  end

  def handle_mouse_click(x, y, action)
    if action == :add
      case @current_tool
      when :platform
        add_platform(x, y)
      when :coin
        add_coin(x, y)
      when :enemy
        add_enemy(x, y)
      when :player
        set_player(x, y)
      when :goal
        set_goal(x, y)
      end
    elsif action == :remove
      remove_element_at(x, y)
    end
  end

  def add_platform(x, y)
    platform = {
      x: (x - 50).round(-1), # Centruj względem kursora
      y: y.round(-1),
      width: 100,
      height: 20,
      sprite: Rectangle.new(
        x: (x - 50).round(-1),
        y: y.round(-1),
        width: 100,
        height: 20,
        color: 'green'
      )
    }
    @elements[:platforms] << platform
  end

  def add_coin(x, y)
    coin = {
      x: (x - 7).round(-1), # Centruj względem kursora
      y: (y - 7).round(-1),
      sprite: Square.new(
        x: (x - 7).round(-1),
        y: (y - 7).round(-1),
        size: 15,
        color: 'yellow'
      )
    }
    @elements[:coins] << coin
  end

  def add_enemy(x, y)
    enemy = {
      x1: x.round(-1),
      y1: y.round(-1),
      x2: (x + 100).round(-1),
      y2: y.round(-1),
      sprite: Rectangle.new(
        x: x.round(-1),
        y: y.round(-1),
        width: 30,
        height: 30,
        color: 'red'
      )
    }
    @elements[:enemies] << enemy
  end

  def set_player(x, y)
    @elements[:player]&.sprite&.remove
    @elements[:player] = {
      x: x.round(-1),
      y: y.round(-1),
      sprite: Triangle.new(
        x1: x.round(-1), y1: y.round(-1) + 30,
        x2: x.round(-1) + 30, y2: y.round(-1) + 30,
        x3: x.round(-1) + 15, y3: y.round(-1),
        color: 'blue'
      )
    }
  end

  def set_goal(x, y)
    @elements[:goal]&.sprite&.remove
    @elements[:goal] = {
      x: x.round(-1),
      y: y.round(-1),
      sprite: Rectangle.new(
        x: x.round(-1),
        y: y.round(-1),
        width: 40,
        height: 30,
        color: 'fuchsia'
      )
    }
  end

  def update
    handle_tool_selection
    handle_save
    handle_exit
  end

  def handle_tool_selection
    if KEYS['1']
      @current_tool = :platform
      @current_tool_text.text = "Current Tool: Platform"
    elsif KEYS['2']
      @current_tool = :coin
      @current_tool_text.text = "Current Tool: Coin"
    elsif KEYS['3']
      @current_tool = :enemy
      @current_tool_text.text = "Current Tool: Enemy"
    elsif KEYS['4']
      @current_tool = :player
      @current_tool_text.text = "Current Tool: Player"
    elsif KEYS['5']
      @current_tool = :goal
      @current_tool_text.text = "Current Tool: Goal"
    end
  end

  def handle_save
    if KEYS['s']
      save_level
      clean_up
      @game.state = :menu
      @game.menu.show_menu
    end
  end

  def handle_exit
    if KEYS['escape']
      clean_up
      @game.state = :menu
      @game.menu.show_menu
    end
  end

  def save_level
    return unless @elements[:player] && @elements[:goal]

    level_data = {
      player: {
        x: @elements[:player][:x],
        y: @elements[:player][:y]
      },
      goal: {
        x: @elements[:goal][:x],
        y: @elements[:goal][:y]
      },
      platforms: @elements[:platforms].map { |p|
        {
          x: p[:x],
          y: p[:y],
          width: p[:width],
          height: p[:height]
        }
      },
      coins: @elements[:coins].map { |c|
        {
          x: c[:x],
          y: c[:y]
        }
      },
      enemies: @elements[:enemies].map { |e|
        {
          x1: e[:x1],
          y1: e[:y1],
          x2: e[:x2],
          y2: e[:y2]
        }
      }
    }

    # Znajdź następny dostępny numer poziomu
    level_num = 1
    while File.exist?("levels/level#{level_num}.txt")
      level_num += 1
    end

    File.write("levels/level#{level_num}.txt", JSON.pretty_generate(level_data))
  end

  def clean_up
    @gui_elements.each(&:remove)
    @elements.values.flatten.compact.each { |e| e[:sprite]&.remove }
    # Wyczyść handler myszy
    $mouse_handler = nil
  end

  def remove_element_at(x, y)
    # Sprawdź każdy typ elementu
    @elements[:platforms].each_with_index do |platform, index|
      if point_in_rect?(x, y, platform)
        platform[:sprite].remove
        @elements[:platforms].delete_at(index)
        return
      end
    end

    @elements[:coins].each_with_index do |coin, index|
      if point_in_rect?(x, y, coin)
        coin[:sprite].remove
        @elements[:coins].delete_at(index)
        return
      end
    end

    @elements[:enemies].each_with_index do |enemy, index|
      if point_in_rect?(x, y, enemy)
        enemy[:sprite].remove
        @elements[:enemies].delete_at(index)
        return
      end
    end

    if @elements[:player] && point_in_rect?(x, y, @elements[:player])
      @elements[:player][:sprite].remove
      @elements[:player] = nil
      return
    end

    if @elements[:goal] && point_in_rect?(x, y, @elements[:goal])
      @elements[:goal][:sprite].remove
      @elements[:goal] = nil
      return
    end
  end

  def point_in_rect?(x, y, element)
    if element[:x1] # Dla przeciwników
      ex = element[:x1]
      ey = element[:y1]
      ew = 30 # szerokość przeciwnika
      eh = 30 # wysokość przeciwnika
    elsif element[:width] # Dla platform
      ex = element[:x]
      ey = element[:y]
      ew = element[:width]
      eh = element[:height]
    else # Dla monet, gracza i celu
      ex = element[:x]
      ey = element[:y]
      ew = 15 # domyślna szerokość
      eh = 15 # domyślna wysokość
      
      # Specjalne wymiary dla gracza i celu
      if element == @elements[:player]
        ew = 30
        eh = 30
      elsif element == @elements[:goal]
        ew = 40
        eh = 30
      end
    end

    x >= ex && x <= ex + ew && y >= ey && y <= ey + eh
  end
end

class Game
  attr_accessor :state, :menu

  def initialize
    @gui_elements = []
    @current_level = 1
    @state = :menu
    @menu = Menu.new(self)
    @can_move = true
    @level_items = []
    @available_levels = []
    @coins = []
    @platforms = []
    @enemies = []
    @game_over = false
    @game_won = false
    @player = nil
    @goal = nil
  end

  def start_game
    @state = :playing
    reset_game
  end

  def load_custom_level
    clean_up_game
    @state = :level_select
    show_level_select_menu
  end

  def show_level_select_menu
    # Upewnij się, że katalog levels istnieje
    Dir.mkdir('levels') unless Dir.exist?('levels')
    
    # Znajdź wszystkie dostępne poziomy
    @available_levels = Dir.glob("levels/level*.txt").sort_by { |f| 
      f.match(/level(\d+)\.txt/)[1].to_i 
    }
    
    return show_no_levels_message if @available_levels.empty?
    
    @current_level_index = 0
    
    # Pokaż tytuł
    @gui_elements << Text.new(
      "Select Level:",
      x: 350, y: 150,
      size: 25,
      color: 'white'
    )
    
    # Stwórz listę poziomów
    @level_items = @available_levels.map.with_index do |level_file, index|
      level_num = level_file.match(/level(\d+)\.txt/)[1]
      Text.new(
        "Level #{level_num}",
        x: 350,
        y: 200 + (index * 30),
        size: 20,
        color: index == @current_level_index ? 'yellow' : 'white'
      )
    end
    @gui_elements.concat(@level_items)
    
    # Dodaj instrukcje
    @gui_elements << Text.new(
      "Use arrows to select, Enter to confirm, Esc to return",
      x: 250, y: 500,
      size: 15,
      color: 'white'
    )
  end

  def show_no_levels_message
    @gui_elements << Text.new(
      "No custom levels found!",
      x: 350, y: 250,
      size: 20,
      color: 'white'
    )
    @gui_elements << Text.new(
      "Press Esc to return to menu",
      x: 350, y: 280,
      size: 15,
      color: 'white'
    )
  end

  def handle_level_selection
    return if @available_levels.empty?

    if KEYS['up'] && @can_move
      move_level_cursor_up
      @can_move = false
    elsif KEYS['down'] && @can_move
      move_level_cursor_down
      @can_move = false
    elsif KEYS['return'] && @can_move
      select_level
      @can_move = false
    elsif KEYS['escape'] && @can_move
      return_to_menu
      @can_move = false
    elsif !KEYS['up'] && !KEYS['down'] && !KEYS['return'] && !KEYS['escape']
      @can_move = true
    end
  end

  def move_level_cursor_up
    @level_items[@current_level_index].color = 'white'
    @current_level_index = (@current_level_index - 1) % @available_levels.length
    @level_items[@current_level_index].color = 'yellow'
  end

  def move_level_cursor_down
    @level_items[@current_level_index].color = 'white'
    @current_level_index = (@current_level_index + 1) % @available_levels.length
    @level_items[@current_level_index].color = 'yellow'
  end

  def select_level
    return if @current_level_index.nil? || @available_levels.empty?
    
    level_file = @available_levels[@current_level_index]
    @current_level = level_file.match(/level(\d+)\.txt/)[1].to_i
    clean_up_game
    @state = :playing
    reset_game
  end

  def return_to_menu
    @state = :menu
    @gui_elements.each(&:remove)
    @gui_elements.clear
    @menu.show_menu
  end

  def update
    case @state
    when :menu
      @menu.update
    when :level_select
      handle_level_selection
    when :generator
      @generator.update
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
    @level_items = []
    $mouse_handler = nil
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

  def start_level_generator
    @state = :generator
    @generator = LevelGenerator.new(self)
    # Zaktualizuj handler myszy aby obsługiwał akcję
    $mouse_handler = ->(x, y, action) { @generator.handle_mouse_click(x, y, action) if @state == :generator }
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