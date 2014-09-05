Jobs::Application.routes.draw do

  get "/alive" => "alive#index"

  scope "v1" do
    resources :async_jobs, only: [:create, :show, :destroy], 
                           constraints: {id: /.+/}

    resources :cron_jobs, only: [:index, :create, :show, :update, :destroy], 
                           constraints: {id: /.+/}
  end

end
