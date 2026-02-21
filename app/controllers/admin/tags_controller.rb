module Admin
  class TagsController < BaseController
    def search
      tags = Tag.search(params[:q].to_s).alphabetical.limit(10)
      render json: tags.map { |t| { id: t.id, name: t.name } }
    end
  end
end
