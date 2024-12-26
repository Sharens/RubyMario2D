module ProjectName
  module Services
    class AuthenticationService
      def initialize(user)
        @user = user
      end

      def authenticate(password)
        # Logika autentykacji
        true
      end
    end
  end
end 