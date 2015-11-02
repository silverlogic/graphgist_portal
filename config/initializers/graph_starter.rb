GraphStarter.configure do |config|
  config.menu_models = %i(GraphGist)

  config.icon_classes = {
    GraphGist: 'file text icon',
    Person: 'user'
  }

  config.scope_filters = {
    GraphGist: -> (graph_gists) do
      graph_gists.where(status: 'live')
    end
  }
end
