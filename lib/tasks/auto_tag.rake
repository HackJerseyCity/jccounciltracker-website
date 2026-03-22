namespace :tags do
  desc "Seed default auto-tag rules (only adds rules to tags that have none)"
  task seed_rules: :environment do
    AutoTaggingService.seed_default_rules!
    count = TagRule.count
    puts "Done. #{count} tag rules now in database."
  end

  desc "Auto-tag all agenda items using tag rules from the database"
  task backfill: :environment do
    if TagRule.none?
      puts "No tag rules found. Run `rails tags:seed_rules` first."
      exit 1
    end

    items = AgendaItem.all
    puts "Auto-tagging #{items.count} items..."
    AutoTaggingService.new(items.to_a).call
    tagged = AgendaItem.joins(:tags).distinct.count
    puts "Done. #{tagged} items now have tags."
  end
end
