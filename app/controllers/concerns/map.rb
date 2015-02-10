module Map
  extend ActiveSupport::Concern

  def map
    render layout: 'map'
  end
end