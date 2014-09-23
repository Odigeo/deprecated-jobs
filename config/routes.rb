Jobs::Application.routes.draw do

  get "/alive" => "alive#index"
  put "/execute_cron_jobs" => "cron_jobs#execute"

  scope "v1" do
    resources :async_jobs, only: [:create, :show, :destroy], 
                           constraints: {id: /([0-9a-f]+-){4}[0-9a-f]+/} do
      collection do
      	put "cleanup"
      end
    end

    resources :cron_jobs, only: [:index, :create, :show, :update, :destroy], 
                           constraints: {id: /([0-9a-f]+-){4}[0-9a-f]+/} do
      member do
        put 'run'
      end
    end
  end

end
