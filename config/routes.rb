Jobs::Application.routes.draw do

  get "/alive" => "alive#index"
  scope "v1" do
  	# Put resource routes here

  end

end
