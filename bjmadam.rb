#! /usr/bin/env ruby
# encoding: UTF-8

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'typhoeus'
# require 'json'

##variables definitions
@directory_name = "BonjourMadame"
@file_name = "Madame"
@url = "http://www.bonjourmadame.fr/page"
##end of variables definitions

##Functions définition
#grab the page who contains the Madame
def madam_page(page_number)
  Nokogiri::HTML(open("#{@url}/#{page_number}"))
end

#get all the Madames that you have already stored
def present_madam
  begin
    Dir.chdir @directory_name
  rescue Errno::ENOENT => pouet
    puts "Doesn't find \"#{@directory_name}\" directory, create it now !"
    Dir.mkdir @directory_name
    Dir.chdir @directory_name
  end
  Dir.glob("#{@file_name}_*.jpg").map! { |file| Integer(file.scan(/\d+/).first) }
end

#retrive the url of a Madame's picture
def picture_url(page)
  page.css('div.photo').children.each do |node|
    if node.name == "a"
      yield node.attributes["href"].value
    elsif node.name == "img"
      yield node.attributes["src"].value
    end
  end
end

##end of function definitions

## "main"
if __FILE__ == $0
  #checking console argument
  case ARGV.first
  when "-h", "--help", "/h", "/?"
    puts "Usage : bjmadam.rb <argument> \n\tdirectory : the directory to save all the Madame\n\t\tdefault : current_directory/BonjourMadame\n\t -h, --help : this screen\nCreated by Ashita"
    exit
  when /\w/
    @directory_name = ARGV.first if File.directory? ARGV.first
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
  
  puts "#{madam_on_disk.length} found in this directory" if madam_on_disk.any?

  #check if we have some work ;)
  if madam_wanted.length > 0
    puts "We found #{madam_wanted.length} \"Madame\" to download ! !"
  else
    puts "Hey, calm down ! ! You need to wait for 10 a.m. of the day to have a new pict ;)"
  end

  #init Typhoeus
  hydra = Typhoeus::Hydra.new :max_concurrency => 20

  #do work
  madam_wanted.each do |n|
    madam_number = Integer(n)
    page = max_madam - madam_number + 1
    request = Typhoeus::Request.new("#{@url}/#{page}", :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_1; en-us) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10")
    request.on_complete do |response|
      puts "Fetching Madame #{n} on page #{page}"
      Nokogiri::HTML(response.body).css('div.photo').children.each do |node|
        if image_link = node.name == "a" ? node.attributes["href"].value : node.name == "img" ? node.attributes["src"].value : nil
          img_request = Typhoeus::Request.new(image_link, :user_agent => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_1; en-us) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10", :follow_location => true)
          img_request.on_complete do |response|
            if response.body
              File.open("#{@file_name}_#{madam_number}.jpg", 'w') {|f| f.write(response.body) }
              puts "#{@file_name}_#{madam_number}.jpg writted"
            end
          end
          hydra.queue img_request
        end
      end if response.body
    end
    hydra.queue request
  end

  hydra.run
end
