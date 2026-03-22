class AutoTaggingService
  # Default rules used to seed tag_rules when no rules exist in the database.
  # Format: { tag: "tag name", rules: [{ pattern: "text", match_type: "keyword"|"phrase" }] }
  DEFAULT_RULES = [
    { tag: "parking",         rules: [ { pattern: "parking", match_type: "keyword" } ] },
    { tag: "taxes",           rules: [ { pattern: "tax abate", match_type: "phrase" },
                                        { pattern: "property tax", match_type: "phrase" },
                                        { pattern: "payroll tax", match_type: "phrase" },
                                        { pattern: "real estate tax", match_type: "phrase" } ] },
    { tag: "payroll",         rules: [ { pattern: "payroll", match_type: "keyword" },
                                        { pattern: "salary", match_type: "keyword" },
                                        { pattern: "salaries", match_type: "keyword" } ] },
    { tag: "fees",            rules: [ { pattern: "fee schedule", match_type: "phrase" } ] },
    { tag: "street safety",   rules: [ { pattern: "vehicles and traffic", match_type: "phrase" } ] },
    { tag: "bike lanes",      rules: [ { pattern: "bicycle", match_type: "keyword" },
                                        { pattern: "bike", match_type: "keyword" },
                                        { pattern: "greenway", match_type: "keyword" },
                                        { pattern: "scooter", match_type: "phrase" } ] },
    { tag: "environmental",   rules: [ { pattern: "soil remed", match_type: "phrase" },
                                        { pattern: "chromate", match_type: "keyword" },
                                        { pattern: "environmental protection", match_type: "phrase" },
                                        { pattern: "contaminat", match_type: "phrase" },
                                        { pattern: "flood hazard", match_type: "phrase" },
                                        { pattern: "underground storage tank", match_type: "phrase" } ] },
    { tag: "building",        rules: [ { pattern: "redevelopment plan", match_type: "phrase" },
                                        { pattern: "land development", match_type: "phrase" } ] },
    { tag: "leases",          rules: [ { pattern: "lease", match_type: "keyword" } ] },
    { tag: "Infrastructure",  rules: [ { pattern: "department of infrastructure", match_type: "phrase" },
                                        { pattern: "division of engineering", match_type: "phrase" } ] },
    { tag: "budget",          rules: [ { pattern: "budget", match_type: "keyword" },
                                        { pattern: "appropriation", match_type: "phrase" } ] },
    { tag: "cannabis",        rules: [ { pattern: "cannabis", match_type: "keyword" } ] },
    { tag: "parks",           rules: [ { pattern: "park maintenance", match_type: "phrase" },
                                        { pattern: "recreation and youth", match_type: "phrase" },
                                        { pattern: "pershing field", match_type: "phrase" },
                                        { pattern: "liberty state park", match_type: "phrase" } ] },
    { tag: "housing",         rules: [ { pattern: "affordable housing", match_type: "phrase" },
                                        { pattern: "housing trust", match_type: "phrase" } ] },
    { tag: "appointments",    rules: [ { pattern: "appointing", match_type: "keyword" },
                                        { pattern: "appointment of", match_type: "phrase" } ] },
    { tag: "claims",          rules: [ { pattern: "payment of a claim", match_type: "phrase" },
                                        { pattern: "settlement of the action", match_type: "phrase" } ] },
    { tag: "grants",          rules: [ { pattern: "community development block grant", match_type: "phrase" },
                                        { pattern: "grant fund", match_type: "phrase" } ] },
    { tag: "public safety",   rules: [ { pattern: "department of public safety", match_type: "phrase" },
                                        { pattern: "division of fire", match_type: "phrase" },
                                        { pattern: "division of police", match_type: "phrase" } ] },
    { tag: "senior services", rules: [ { pattern: "senior citizen", match_type: "phrase" },
                                        { pattern: "senior center", match_type: "phrase" },
                                        { pattern: "senior meal", match_type: "phrase" },
                                        { pattern: "senior lunch", match_type: "phrase" },
                                        { pattern: "senior affair", match_type: "phrase" },
                                        { pattern: "congregate", match_type: "phrase" } ] },
    { tag: "water",           rules: [ { pattern: "water agreement", match_type: "phrase" },
                                        { pattern: "jcmua", match_type: "keyword" } ] }
  ].freeze

  def initialize(agenda_items)
    @agenda_items = Array(agenda_items)
  end

  def call
    return if @agenda_items.empty?

    load_rules
    @agenda_items.each { |item| tag_item(item) }
  end

  # Seeds default rules for tags that have no rules yet.
  # Safe to call multiple times — only adds rules to tags that have none.
  def self.seed_default_rules!
    DEFAULT_RULES.each do |entry|
      tag = Tag.where("LOWER(name) = ?", entry[:tag].downcase).first_or_create!(name: entry[:tag])
      next if tag.tag_rules.any?

      entry[:rules].each do |rule|
        tag.tag_rules.create!(pattern: rule[:pattern], match_type: rule[:match_type])
      end
    end
  end

  private

  def load_rules
    @rules = Tag.joins(:tag_rules)
                .includes(:tag_rules)
                .distinct
                .map do |tag|
                  regexes = tag.tag_rules.map(&:to_regex)
                  { tag: tag, regexes: regexes }
                end
  end

  def tag_item(item)
    title = item.title.to_s

    @rules.each do |rule|
      if rule[:regexes].any? { |pat| pat.match?(title) }
        item.agenda_item_tags.find_or_create_by!(tag: rule[:tag])
      end
    end
  end
end
