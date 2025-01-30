# frozen_string_literal: true

class ExampleController < ActionController::Base
  def index
    render plain: 'OK'
  end
end
