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

    cuisines = ['American', 'Sushi']

    budget_low = 10

    find_restaurant(address, cuisines, budget_low)
  end


  def find_restaurant(address, cuisines, budget_low)
    # Get a list of all restaurants that deliver to this address from the API
    @all_restaurants = @api.delivery_list(address)

    # Filter down to the valid restaurants for this purpose
    @valid_restaurants = get_valid_restaurants(@all_restaurants, cuisines, budget_low)

    # Grab a random validated restaurant!
    @restaurant = @valid_restaurants.sample

    # Get restaurant info from API

    render :json => @restaurant
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
