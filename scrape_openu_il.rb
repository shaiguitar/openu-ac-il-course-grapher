# encoding: UTF-8

require 'mechanize'
require 'pry'

Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8
USER_AGENT_STR = 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1623.0 Safari/537.36'

def strip_utf_whitespace(str)
  str.split("").reject{|c| c.ord == 8236 || c.ord == 8235 }.join
end

class HTTPhaxer

  def initialize(url)
    @agent = Mechanize.new { |agent| agent.user_agent = USER_AGENT_STR }
    @url = url
  end

  def course_name
    return @course_name if @course_name # memoize
    @agent.get(@url) do |page|

      # EXTRACT COURSE NAME
      course_name = page.title.dup
      course_name.gsub!(/\d+/,"") # rm course number, just want name. then rm whitespace
      words = course_name.split
      @course_name = words.map do |word|
        strip_utf_whitespace(word)
      end.join(" ").strip!
    end
    @course_name
  end

  # mapping for requisites courses
  # course_name => [need_this, need_this_too]
  def name_url_map
    return @name_url_map if @name_url_map # memoize
    @agent.get(@url) do |page|
      # EXTRACT REQUISITES
      #
      # name => url mapping
      #
      # @todo filter these so it only gets fully required, not both those and suggested courses...shitty html is shitty.
      # wtf bad html layouts, why why why SEMANTIC IT....  ידע קודם מומלץ
      nokogiri_document = page.parser
      nokogiri_document.at_css('#course_title')
      the_element = nokogiri_document.at_css('#course_title').next_element.next_element.next_element
      found = the_element.children.select{|e| e.name == 'a'}
      @name_url_map = Hash[found.map{|a| [a.text.to_s, a['href'].to_s] }]
    end
    @name_url_map
  end

  def requisite_names
    names = name_url_map.keys
    names.map{|n| x = n.dup; x.strip!; x }
  end

  def requisite_urls
    name_url_map.values.map{|u|
      if u.match /http/
        u
      else
        "http://www.openu.ac.il/courses/#{u}"
      end
    }
  end
end


class BuildDepdencyHash

  class << self

    attr_reader :dependency_hash, :failures
    def do_it(url)
      @dependency_hash = {}
      @failures = []
      run_for(url)
    end

    def run_for(url)
      http_haxer = HTTPhaxer.new(url)
      puts "=========================================="
      puts "In url #{url} (#{http_haxer.course_name})"
      puts "=========================================="
      @dependency_hash[http_haxer.course_name] = http_haxer.requisite_names
      other_urls = http_haxer.requisite_urls
      other_urls.each do |url|
        run_for(url)
      end
    rescue => e
      puts "FAILURE at #{url}: #{e.message}"
      @failures << [http_haxer, e]
      # and move again to the next.
    end
  end

end
