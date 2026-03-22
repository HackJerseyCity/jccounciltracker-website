class TagRule < ApplicationRecord
  belongs_to :tag

  enum :match_type, {
    keyword: "keyword",
    phrase: "phrase"
  }

  validates :pattern, presence: true
  validates :match_type, presence: true

  normalizes :pattern, with: ->(p) { p.strip }

  def to_regex
    escaped = Regexp.escape(pattern)
    if keyword?
      /\b#{escaped}\b/i
    else
      /\b#{escaped}/i
    end
  end
end
