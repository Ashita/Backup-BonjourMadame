#! /usr/bin/env ruby
# encoding: UTF-8

require 'rubygems'
require 'bundler/setup'

#gems
require 'nokogiri'
require 'typhoeus'
require 'awesome_print'

require 'open-uri'

##variables definitions
DIRECTORY_NAME = "BonjourMadame"
FILE_NAME = "Madame"
URL = "http://www.bonjourmadame.fr/page"

# DIRECTORY_NAME = "BonjourPanda"
# @file_name = "Panda"
# URL = "http://www.bonjourpanda.fr/page"

# DIRECTORY_NAME = "BonjourGeek"
# @file_name = "Geek"
# URL = "http://bonjourlesgeeks.com/page"

##Functions définition
def madam_page(page_number)
  Nokogiri::HTML(open("#{URL}/#{page_number}"))
end

def present_madam
  begin
    Dir.chdir DIRECTORY_NAME
  rescue Errno::ENOENT => pouet
    puts "Doesn't find \"#{DIRECTORY_NAME}\" directory, create it now !"
    Dir.mkdir DIRECTORY_NAME
    Dir.chdir DIRECTORY_NAME
  end
  Dir.glob("#{FILE_NAME}_*.jpg").map! { |file| Integer(file.scan(/\d+/).first) }
end

def add_request(hydra, url)
  request = Typhoeus::Request.new(url, :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_1; en-us) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10", :follow_location => true)
  request.on_complete do |response|
    yield response
  end
  hydra.queue request
end

def add_request_for_image(hydra, url, madam_number)
  add_request(hydra, url) do |response|
    if response.body
      File.open("#{FILE_NAME}_#{madam_number}.jpg", 'w') {|f| f.write(response.body) }
      puts "#{FILE_NAME}_#{madam_number}.jpg writted"
    end
  end
end

##end of function definitions

## "main"
if __FILE__ == $0
  #checking console argument
  case ARGV.first
  when "-h", "--help", "/h", "/?"
    puts "Usage : bjmadam.rb <argument> \n\tdirectory : the directory to save all the \"Madame\"\n\t\tdefault : current_directory/BonjourMadame\n\t -h, --help : this screen\nCreated by Ashita"
    exit
  when /\w/
    DIRECTORY_NAME = ARGV.first if File.directory? ARGV.first
  when nil
    puts "No directory specified, select default one : #{Dir.pwd}"
  else
    puts "unknow argument : #{ARGV.first}"
    exit
  end

  #get the number of Madame on line
  @fucking_useless_page = 1
  max_madam = Integer(madam_page(1).css('div#pages')[0].text.scan(/\d+/).last) - @fucking_useless_page
  #and remove to that the picture that you already have
  madam_on_disk = present_madam
  madam_wanted = (1..max_madam).to_a - madam_on_disk

  puts "#{madam_on_disk.length} \"Madame\" found in this directory" if madam_on_disk.any?

  #check if we have some work ;)
  if madam_wanted.length > 0
    puts "We found #{madam_wanted.length} \"Madame\" to download ! !"
  else
    puts "Hey, calm down ! ! You need to wait for 10 a.m. of the day to have a new pict ;)"
  end

  #init Typhoeus
  hydra = Typhoeus::Hydra.new :max_concurrency => 5

  #do work
  madam_wanted.each do |n|
    madam_number = Integer(n)
    page = max_madam - madam_number + 1
    add_request(hydra, "#{URL}/#{page}") do |response|
      puts "Fetching \"Madame\" #{n}"
      if response.body
        Nokogiri::HTML(response.body).css('div.photo').children.each do |node|
          if node.name == "a"
            add_request(hydra, node.attributes["href"].value) do |response|
              if response.body
                image = Nokogiri::HTML(response.body).css('#image').first
                image ? add_request_for_image(hydra, image.attributes['src'].value, madam_number) : puts("can't download \"Madame\" #{madam_number} on #{URL}/#{page}")
              else
                puts "no page for \"Madame\"#{n} on #{URL}/#{page}"
              end
            end
            break;
          elsif image_link = node.name == "img" ? node.attributes["src"].value : nil
            add_request_for_image(hydra, image_link, madam_number)
            break;
          end
        end
      else
        puts "Page #{URL}/#{page} not found"
      end
    end
  end

  hydra.run
end
