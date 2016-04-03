require 'json'
require 'pry'
require 'colorize'

def json_from(json_file)
  JSON.parse(File.read(json_file), symbolize_names: true)
end

def percentage(x, y)
  return 0 if y.zero?
  x * 100.to_f / y
end

cfile = ARGV.first || "countries.json" or abort "Usage: #$0 <countries file>"
@countries = json_from(cfile)

puts <<'eoheader'
{| class="wikitable sortable"
|-
! Country !! Legislature !! Total Members !! Matched to Wikidata !! Percentage !! Parties !! Matched !! Pct
|-
eoheader

total = { persons: 0, matched: 0 }
@countries.each do |c|
  c[:legislatures].each do |l|
    @json = json_from l[:popolo]
    wdid = @json[:organizations].find { |o| o[:classification] == 'legislature' }[:identifiers].find { |i| i[:scheme] == 'wikidata' }[:identifier]

    persons = @json[:persons]
    parties = @json[:organizations].select { |o| o[:classification] == 'party' }.reject { |o| o[:name].downcase == 'unknown' }

    wdp = persons.partition { |p| (p[:identifiers] || []).find { |i| i[:scheme] == 'wikidata' } }
    wdg = parties.partition { |p| (p[:identifiers] || []).find { |i| i[:scheme] == 'wikidata' } }

    puts "|-"
    puts "| %s || {{Q|%s}} || %d || %d || %.0f%% || %d || %d || %0.f%%" % [
      c[:name], wdid.sub('Q',''), 
      persons.count, wdp.first.count, percentage(wdp.first.count, persons.count),
      parties.count, wdg.first.count, percentage(wdg.first.count, parties.count),
    ]
    total[:persons] += persons.count
    total[:matched] += wdp.first.count
  end
end

puts "|}"

# only warn so that we can paste STDOUT to Wikidata without this
warn "Total: %d / %d (%0.f%%)" % [total[:matched], total[:persons], total[:matched] * 100.to_f / total[:persons]]
