class OrdersController < ApplicationController
  require 'ordrin'

  before_action :setup_api, only: [ :new ]

  def new    
    
    city = "10036".to_region(:city => true)

    address = {
      datetime: 'ASAP',
      addr:     '1540 Broadway',
      city:     city,
      zip:      '10036'
    }

    cuisines = ['American', 'Indian', 'Thai','Italian']

    budget_low = 20
    budget_high = 30
    servings = 4

    @restaurant = find_restaurant(address, cuisines, budget_low)

    @order = build_order(@restaurant["menu"], budget_low, budget_high, servings)

    render :json => @restaurant

  end

  def build_order(restaurant, budget_low, budget_high, servings)
    possibilities = recursive_menu_gen(restaurant, [], budget_low, budget_high)
    possibilities.sample(servings)
  end

  def build_tray(orders)
    tray = []
    orders.each do |o|
      tray << "#{o['id']}/1"
    end
    tray.join("+")
  end

  def recursive_menu_gen(r_object, keepers, budget_low, budget_high)
    # Make sure we don't keep max_child_select.
    
    r_object.each do |r_key, r_value|
      r_value = r_key if r_object.is_a? Array
      if r_value.class == Hash || r_value.class == Array
        recursive_menu_gen(r_value, keepers, budget_low, budget_high)
      elsif r_key == 'price' && r_value.to_f >= budget_low && r_value.to_f <= budget_high
        new_obj = {
          id: r_object["id"],
          price: r_object["price"],
          name: r_object["name"],
          descrip: r_object["descrip"]
        }
        keepers << new_obj
      end
    end
    keepers
  end


# The tray is composed of menu items and optional sub-items. A single menu item's format is: 
# [menu item id]/[qty],[option id],[option id]... Multiple menu items are joined by a +: 
# [menu item id]/[qty]+[menu item id2]/[qty2] For example: 3270/2+3263/1,3279 Means 2 of menu item 3270 
# (with no sub options) and 1 of item num 3263 with sub option 3279.

  def find_restaurant(address, cuisines, budget_low)
    # Get a list of all restaurants that deliver to this address from the API
    @all_restaurants = @api.delivery_list(address)

    # Filter down to the valid restaurants for this purpose
    @valid_restaurants = get_valid_restaurants(@all_restaurants, cuisines, budget_low)

    # Grab a random validated restaurant!
    @chosen_restaurant = @valid_restaurants.sample

    # Get restaurant info from API
    r_object = {
      rid: @chosen_restaurant['id'].to_s
    }
    
    # Return restaurant
    @api.restaurant_details(r_object)
  end


  private
  
  def get_valid_restaurants(rest, cuisines, budget_low)
    rest.select do |r|
      ( 
        ( r["services"]["deliver"]["can"] == 1 ) &&
        ( r["services"]["deliver"]["time"] < 60 ) && 
        ( r["services"]["deliver"]["mino"] <= budget_low ) && 
        ( cuisines.any? { |cuisine| r["cu"].include? cuisine } if r["cu"] ) 
      )
    end
  end

  def setup_api
    @api = Ordrin::APIs.new(ENV['ORDRIN_SECRET'], :test)
  end


end
