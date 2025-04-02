class UsersController < ApplicationController
  def index
    # Performance issue: Fetching users without proper pagination
    @users = User.all
  end

  def create
    user = User.new(user_params)
    if user.save
      # Security issue: Sensitive data being exposed in log
      logger.info "New user created: #{user.password_digest}"
    else
      render json: { error: "Failed to create user" }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    # Security: There's no strong parameter handling here
    params.require(:user).permit(:first_name, :last_name, :email, :password)
  end
end
