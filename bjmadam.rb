#! /usr/bin/env ruby
# encoding: UTF-8

require 'rubygems'
require 'nokogiri'
require 'open-uri'

##variables definitions
@directory_name = "BonjourMadame"
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
  Dir.glob('Madame*.jpg').map! { |file| Integer(file.scan(/\d+/).first) }
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

#save picture data in a file
def save_in_file(madam_number, data)
  file_name = "Madame_#{madam_number}.jpg"
  begin
    File.open(file_name, "wb") do |file|
      file.write data
    end    
  rescue SystemCallException => e
    puts "Problème de permissions pour l'écriture"
    throw e
  end
  puts "=> #{file_name} writed succesfully"
end

def madame_to_her_page(madam_number, max_madames)
  max_madames - madam_number + 1
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
  @max_madam = Integer(madam_page(1).css('div#pages')[0].text.scan(/\d+/).last) - @fucking_useless_page
  #and remove it the madame that you already have
  madam_wanted = (1..@max_madam).to_a - present_madam

  #check if we have some work ;)
  if madam_wanted.length > 0
    puts "We found #{madam_wanted.length} \"Madame\" to download ! !"
  else
    puts "Hey, calm down ! ! You need to wait for 10 a.m. of the day to have a new pict ;)"
  end

  #do work
  madam_wanted.each do |n|
    page = madame_to_her_page Integer(n), @max_madam
    puts "Fetching Madame #{n} on page #{page}"
    picture_url(madam_page(page)) do |link|
      save_in_file n, open(link).read
    end
  end
end
