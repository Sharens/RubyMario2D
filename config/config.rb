module ProjectName
  class Configuration
    class << self
      attr_accessor :api_key, :environment

      def configure
        yield self if block_given?
      end
    end
  end
end 