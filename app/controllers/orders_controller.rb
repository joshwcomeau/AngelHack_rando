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

    find_restaurants(address, cuisines)
  end


  def find_restaurants(address, cuisines)
    @restaurants = @api.delivery_list(address)
    render :json => get_valid_restaurants(@restaurants, cuisines)
  end


  private
  
  def get_valid_restaurants(rest, cuisines)
    rest.select do |r|
      validate_restaurant(r, cuisines)
    end
  end

  def validate_restaurant(rest, cuisines)
    ( 
      ( cuisines.any? { |cuisine| rest["cu"].include? cuisine } if rest["cu"] ) && 
      ( rest["services"]["deliver"]["time"] < 60 ) && 
      ( rest["is_delivering"] == 1 )
    )
  end

  def setup_api
    @api = Ordrin::APIs.new(ENV['ORDRIN_SECRET'], :test)
  end


end
