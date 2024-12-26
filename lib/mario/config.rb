module Mario
  module Config
    class << self
      def setup
        setup_window
        setup_input_handling
        setup_directories
      end

      private

      def setup_window
        set title: "Super Mario Ruby", 
            width: 800, 
            height: 600
      end

      def setup_input_handling
        $mouse_handler = nil
        @keys = {}

        on :key_down do |event|
          @keys[event.key] = true
        end

        on :key_up do |event|
          @keys[event.key] = false
        end

        on :mouse_down do |event|
          if $mouse_handler
            action = event.button == :left ? :add : :remove
            $mouse_handler.call(event.x, event.y, action)
          end
        end
      end

      def setup_directories
        Dir.mkdir('levels') unless Dir.exist?('levels')
      end
    end
  end
end 