module ProjectName
  module Controllers
    class UsersController
      def index
        # Logika pobierania użytkowników
      end

      def create(user_params)
        user = Models::User.new(user_params)
        # Logika tworzenia użytkownika
      end
    end
  end
end 