require 'everypolitician'
require 'csv'
require 'pry'

popolo = Everypolitician::Popolo.read('ep-popolo-v1.0.json')
persons = popolo.persons

term_10_ids = popolo.persons.reject do |pers|
  pers.memberships.find_by(legislative_period_id: 'term/10').nil?
end.map(&:id)

term_9_ids = popolo.persons.reject do |pers|
  pers.memberships.find_by(legislative_period_id: 'term/9').nil?
end.map(&:id)

common_members = term_9_ids & term_10_ids

def member_row(id)
  popolo = Everypolitician::Popolo.read('ep-popolo-v1.0.json')
  person = popolo.persons.find_by(id: id)
  [
    person.name,
    person.other_names.select { |p| p[:lang] == 'ar' }.map { |p| p[:name] }.join(';'),
    person.memberships.map { |p| p[:legislative_period_id] }.join(';'),
    person.memberships.map { |p| p.party[:name] }.join(';'),
    person.sources.map { |p| p[:url] }.join(';'),
    person.id,
  ]
  # binding.pry
end

def csv_out(arr, filename)
  CSV.open("#{filename}.csv", 'w') do |csv|
    csv << %w(name__en name__ar term party source UUID)
    arr.each do |a|
      row = member_row(a)
      puts row.join(' ')
      csv << row
    end
  end
end

csv_out(term_10_ids, 'term_10_members')
csv_out(common_members, 'members_in_term_9_and_term_10')
