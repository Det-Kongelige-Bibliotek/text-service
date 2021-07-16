Rails.application.routes.draw do

  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  devise_for :users
    concern :searchable, Blacklight::Routes::Searchable.new

  resources :id
  get '/:id', action: :collection, controller: 'catalog', constraints: {id: /adl|gv|pmm|sks|lhv|tfs|letters/ }

  resource :catalog, only: [:index], as: 'catalog', path: '/text', controller: 'catalog' do
    concerns :searchable
    concerns :range_searchable

  end

  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/text', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  mount Blacklight::Engine => '/'
  root to: "catalog#index"

    get '/catalog/:id/facsimile' => 'catalog#facsimile', as: 'facsimile_catalog'


  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'periods' => 'catalog#periods'
  get 'authors' => 'catalog#authors'

  get 'oai' => 'catalog#oai'

  resources :snippet
  get '/comment/:id' => 'snippet#comment'

end
