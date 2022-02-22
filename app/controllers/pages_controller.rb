class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]
  before_action :authenticate_user!, only: [:user_profile]

  def home
    @cosmetics = Cosmetic.first(5)
  end

  def user_profile
  end
end
