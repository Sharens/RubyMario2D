module ProjectNames
  module Models
    class User
      attr_accessor :id, :email, :name

      def initialize(attributes = {})
        @id = attributes[:id]
        @email = attributes[:email]
        @name = attributes[:name]
      end

      def valid?
        !email.nil? && !name.nil?
      end
    end
  end
end 