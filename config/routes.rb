Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "materials#index"

  resources :materials do
    collection do
      post :import_csv
      delete :delete_all_imported
    end
  end
end
