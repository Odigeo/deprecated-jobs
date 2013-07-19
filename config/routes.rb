Jobs::Application.routes.draw do

  get "/alive" => "alive#index"

  scope "v1" do
    resources :async_jobs, except: :update, constraints: {id: /.+/}
  end

end
