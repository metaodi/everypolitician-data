require_relative './wikidata_lookup'
require 'json'
require 'csv'

class Fetcher
  def self.regenerate(i)
    new(i).fetch
  end

  def initialize(i)
    @instructions = i
  end

  def i(k)
    @instructions[k.to_sym]
  end

  def c(k)
    i(:create)[k.to_sym]
  end

  def source
    c(:source)
  end

  def copy_url(url)
    IO.copy_stream(open(url), i(:file))
  end
  
  def fetch
    FileUtils.mkpath File.dirname i(:file)
    warn "Regenerating #{i(:file)}"
    write
  end
end

class Fetcher::GenderBalance < Fetcher
  def write
    remote = "http://www.gender-balance.org/export/#{source}"
    copy_url(remote)
  end
end

class Fetcher::Morph < Fetcher
  def morph_select(src, qs)
    morph_api_key = ENV['MORPH_API_KEY'] or fail 'Need a Morph API key'
    key = ERB::Util.url_encode(morph_api_key)
    query = ERB::Util.url_encode(qs.gsub(/\s+/, ' ').strip)
    url = "https://api.morph.io/#{src}/data.csv?key=#{key}&query=#{query}"
    open(url).read
  end

  def write
    data = morph_select(c(:scraper), c(:query))
    File.write(i(:file), data)
  end
end

class Fetcher::OCD < Fetcher
  def write
    remote = 'https://raw.githubusercontent.com/opencivicdata/ocd-division-ids/master/identifiers/' + source
    copy_url(remote)
  end
end

class Fetcher::Parlparse < Fetcher
  def write
    gh_url = 'https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/data/'
    term_file_url = gh_url + '%s/sources/manual/terms.csv'
    instructions_url = gh_url + '%s/sources/parlparse/instructions.json'
    cwd = Dir.pwd.split("/").last(2).join("/")

    args = {
      terms_csv: term_file_url % cwd,
      instructions_json: instructions_url % cwd,
    }
    remote = 'https://parlparse-to-csv.herokuapp.com/?' + URI.encode_www_form(args)
    copy_url(remote)
  end
end

class Fetcher::URL < Fetcher
  def write
    copy_url(c(:url))
  end
end

class Fetcher::Wikidata < Fetcher
  def lookup_class
    WikidataLookup
  end

  def write
    mapping = CSV.table("sources/#{source}", converters: nil)
    wikidata = lookup_class.new(mapping)
    File.write(i(:file), JSON.pretty_generate(wikidata.to_hash))
  end
end

class Fetcher::Wikidata::Area < Fetcher::Wikidata
end

class Fetcher::Wikidata::Group < Fetcher::Wikidata
  def lookup_class
    GroupLookup
  end
end

