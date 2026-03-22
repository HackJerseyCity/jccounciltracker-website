class ProfilesController < ApplicationController
  def edit
    @user = Current.user
  end

  def update
    @user = Current.user

    unless @user.authenticate(params.dig(:user, :current_password).to_s)
      @user.errors.add(:current_password, "is incorrect")
      return render :edit, status: :unprocessable_entity
    end

    update_params = profile_params.except(:current_password)
    update_params = update_params.reject { |k, v| k.in?(%w[password password_confirmation]) && v.blank? }

    if @user.update(update_params)
      redirect_to edit_profile_path, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.expect(user: [ :name, :email_address, :password, :password_confirmation, :current_password, :email_notifications ])
  end
end
