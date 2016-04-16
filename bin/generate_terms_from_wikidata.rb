require 'colorize'
require 'csv'
require 'pry'
require 'wikisnakker'

# generate a terms.csv file starting from a given Wikidata page for a
# 'legislative term' and iterating backwards

def fetch_term(q)
  t = Wikisnakker::Item.find(q) or raise "No such item"
  name = t.label('en')
  data = { 
    id: name[/^(\d+)/, 1],
    name: name,
    start_date: t.P580.to_s,
    end_date: t.P582.to_s,
    wikidata: q,
  }
  puts data.values.to_csv

  if prev = t.P155
    fetch_term(prev.value.id) 
  end
end

start_at = ARGV.shift or abort "Usage: #$0 <startingID>"
puts %w(id name start_date end_date wikidata).to_csv

# Start at most-recent term, and follow the 'follows' backwards
fetch_term start_at
