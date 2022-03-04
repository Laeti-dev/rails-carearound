class CosmeticsController < ApplicationController
  before_action :set_cosmectic, only: %i[show compare]
  before_action :skip_authorization, only: [:search, :compare]
  # The user must be logged in to like a cosmetic.
  # The toggle_favorite action is called if the user is logged in,
  # using the Devise helper.
  before_action :authenticate_user!, only: [:toggle_favorite, :update, :index]

  def create
    @cosmetic = Cosmetic.new(cosmetic_params)
    cosmetic_policy_authorize
    if @cosmetic.save
      redirect_to confirm_cosmetic_path(@cosmetic)
    else
      redirect_to scan_path
    end
  end

  def confirm
    @cosmetic = Cosmetic.find(params[:id])
  end

  def new
    cosmetic_policy_authorize
    Cosmetic.new
  end

  def index
    # @cosmetics = policy_scope(Cosmetic).first(50)
    @cosmetics = policy_scope(Cosmetic)
    # When we display all, we get some cosmetics with no brand, description, etc.
    # Display less so we don't get too much errors".
    # Later will implement search button anyway and will get only the ones we look for.

    # @favorite_cosmetics = current_user.favorited_by_type('Cosmetic')
    #manual typing search function below
    if params[:query].present?
      unformatted_search_terms = params[:query].split(",")
      formatted_search_terms = unformatted_search_terms.map { |term| term.squish }
      sql_query = " \
      cosmetics.brand @@ :query \
      OR cosmetics.name @@ :query \
      OR cosmetics.category @@ :query \
      OR tags.name @@ :query \
      "
      @cosmetics = []
      formatted_search_terms.each do |term|
        @cosmetics += Cosmetic.joins(:tags).where(sql_query, query: term).uniq
      end
      @cosmetics
    else
      @cosmetics = policy_scope(Cosmetic).first(50)
    end
  end
  #OR cosmetics.tags.tag_list[] @@ :query \

  def show
    cosmetic_policy_authorize
    @review = Review.new
  end

  def update
    @cosmetic = Cosmetic.find(params[:id])
    #@cosmetic.update(cosmetic_params)
    @cosmetic.tag_list.add(cosmetic_params[:tag_list])
    @cosmetic.save
    cosmetic_policy_authorize
    redirect_to cosmetic_path(@cosmetic)
  end

  def toggle_favorite
    # The toggle_favorite action finds the cosmetic to like through the id parameter.
    @cosmetic = Cosmetic.find_by(id: params[:id])
    cosmetic_policy_authorize
    # It checks if a user has liked it. If it’s been favourited before, it is now unfavorited and vice versa.
    current_user.favorited?(@cosmetic) ? current_user.unfavorite(@cosmetic) : current_user.favorite(@cosmetic)
  end

  def search
    @info = Ocr.extract_text("https://img.makeupalley.com/0/0/1/3/2548142.JPG")
    @cosmetic = Cosmetic.create
    # if this products exists, compare datas with DB
    # else create a new product & save it to our DB
  end

  def compare
    @cosmetic = Cosmetic.find(params[:id])
    @cosmetics = Cosmetic.includes(:ingredients).where.not(ingredients: {id: nil}).where(ingredients: {name_en: @cosmetic.tag_list })
    #@cosmetic_ingredients = Ingredient.find_by([:id]params[:cosmetic_id])

    # After scanning a product and looking in the DB for potential doppleganger, display them
    # But let's start by displaying our json file
    @cosmetics = policy_scope(Cosmetic)
  end

  private

  def cosmetic_policy_authorize
    authorize @cosmetic
  end

  def set_cosmectic
    @cosmetic = Cosmetic.find(params[:id])
  end

  def cosmetic_params
    params.require(:cosmetic).permit(:cosmetic_image, :name, :description, :brand, :average_price, :category, :ingredient_id, tag_list: [])
  end
end
