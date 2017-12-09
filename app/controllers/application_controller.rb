class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    before_action :configure_permitted_parameters, if: :devise_controller?

    protected
    def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:name, :email, :password) }
        devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:name, :email, :password, :current_password) }
    end

    def authenticate_editor!
        redirect_to root_path unless user_signed_in? && current_user.is_editor?
    end

    def authenticate_admin!
        redirect_to root_path unless user_signed_in? && current_user.is_admin?
    end
end
