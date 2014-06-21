class OrdersController < ApplicationController
  require 'ordrin'

  before_action :setup_api, only: [ :new ]

  def new    
    

    address = {
      datetime: 'ASAP',
      addr:     '1540 Broadway',
      city:     'New York',
      zip:      '10036'
    }

    cuisines = ['American', 'Sushi']

    budget_low = 15

    find_restaurants(address, cuisines, budget_low)
  end


  def find_restaurants(address, cuisines, budget_low)
    # Get a list of all restaurants that deliver to this address from the API
    @all_restaurants = @api.delivery_list(address)

    # Filter down to the valid restaurants for this purpose
    @valid_restaurants = get_valid_restaurants(@all_restaurants, cuisines, budget_low)


    render :json => @valid_restaurants
  end


  private
  
  def get_valid_restaurants(rest, cuisines, budget_low)
    rest.select do |r|
      ( 
        ( rest["is_delivering"] == 1 ) &&
        ( rest["services"]["deliver"]["time"] < 60 ) && 
        ( rest["services"]["deliver"]["mino"] >= budget_low ) && 
        ( cuisines.any? { |cuisine| rest["cu"].include? cuisine } if rest["cu"] ) 
      )
    end
  end

  def setup_api
    @api = Ordrin::APIs.new(ENV['ORDRIN_SECRET'], :test)
  end


end
