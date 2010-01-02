#! /usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'

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
  p "unknow argument"
  exit
end
#end of console argument

##Functions définition
#grab the page who contains the Madame
def madam_page(page_number)
  Nokogiri::HTML(open("#{@url}/#{page_number}"))
end

#get the number of Madame that you always have
def number_of_present_madam
  begin
    Dir.chdir @directory_name
  rescue Errno::ENOENT => pouet
    puts "Doesn't find \"#{@directory_name}\" directory, create it now !"
    Dir.mkdir @directory_name
    Dir.chdir @directory_name
  end
  Dir.glob('Madame*.jpg').length
end

##variables définitions
@directory_name = "BonjourMadame"
@url = "http://www.bonjourmadame.fr/page"
@max_madam = Integer(madam_page(1).css('div#pages')[0].text.scan(/\d+/).last)
@present_madam = Integer(number_of_present_madam)
##end of variables définitions

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
  file_name = "Madame_n_#{madam_number}.jpg"
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
##end of function definitions

## "main"
if __FILE__ == $0
  #check if we have some work ;)
  madam_wanted = @max_madam - @present_madam
  if madam_wanted > 0
    puts "We found #{madam_wanted} \"Madame\" to download ! !"
  elsif madam_wanted < 0
    puts "Error, you have more picture than the website. This script need a clean directory"
  else
    puts "Hey, calm down ! ! You need to wait for 10am of the day to have a new pict ;)"
  end

  #do work
  (1..madam_wanted).to_a.reverse.each do |n|
    madam_number = @max_madam + 1 - n
    puts "Fetching Madame #{madam_number} on page #{n}"
    picture_url(madam_page(n)) do |link|
      save_in_file madam_number, open(link).read
    end
  end
end
