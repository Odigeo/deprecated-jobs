Jobs::Application.routes.draw do

  get "/alive" => "alive#index"
  put "/execute_cron_jobs" => "cron_jobs#execute"

  scope "v1" do
    resources :async_jobs, only: [:create, :show, :destroy], 
                           constraints: {id: /.+/}

    resources :cron_jobs, only: [:index, :create, :show, :update, :destroy], 
                           constraints: {id: /.+/}
  end

end
