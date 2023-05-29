module JwtAuthentication
    private
  
    def authenticate_user
      token = extract_token(request.env)


      if token
          begin
              payload = decode_token(token)

              user = User.find(payload['user_id'])

              unless user
                  return unauthenticated_response
              end

              request.env[:current_user] = user
          rescue JWT::DecodeError, JWT::VerificationError
              # Invalid token
              return unauthenticated_response
          end
      else
          return unauthenticated_response
      end
    end

    def check_for_roles(roles)
        user_roles = request.env[:current_user].roles.map {|role| role.name}  
        
        return unauthorized_response if (roles & user_roles).empty?
    end

    def check_for_admin
        userRoles = request.env[:current_user].roles.map {|role| role.name}  

        
        return unauthorized_response unless userRoles.include? "ROLE_ADMIN"
    end

    def check_for_user
        userRoles = request.env[:current_user].roles.map {|role| role.name}  

        return unauthorized_response unless userRoles.include? "ROLE_USER"
    end

    def extract_token(env)
        auth_header = env['HTTP_AUTHORIZATION'] || env["Authorization"]
        return nil unless auth_header

        token = auth_header.split(' ').last
        token if token.present?
    end

    def decode_token(token)
        JWT.decode(token, Rails.application.secret_key_base).first
    end

    def unauthenticated_response
        render json: { msg: 'Unauthenticated' }.to_json, status: 401
    end

    def unauthorized_response
        render json: { msg: 'Unauthorized' }.to_json, status: 403
    end
end