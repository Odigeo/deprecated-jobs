Dummy::Application.routes.draw do

	scope "v1" do
  	  resources :the_models
  	end

end
