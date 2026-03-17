module Starrable
  extend ActiveSupport::Concern

  included do
    has_many :stars, as: :starrable, dependent: :destroy
  end
end
