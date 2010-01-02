#! /usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'

def madam_page(page_number)
  Nokogiri::HTML(open("#{@url}/#{page_number}"))
end

def number_of_present_madam
  begin
    Dir.chdir @directory_name
  rescue Errno::ENOENT => pouet
    puts "Doesn't find \"BonjourMadame\" directory, create it now !"
    Dir.mkdir @directory_name
    Dir.chdir @directory_name
  end
  Dir.glob('Madame*.jpg').length
end

@directory_name = "BonjourMadame"
@url = "http://www.bonjourmadame.fr/page"
@max_madam = Integer(madam_page(1).css('div#pages')[0].text.scan(/\d+/).last)
@present_madam = Integer(number_of_present_madam)

def picture_link(page)
  page.css('div.photo').children.each do |node|
    if node.name == "a"
      yield node.attributes["href"].value
    elsif node.name == "img"
      yield node.attributes["src"].value
    end
  end
end

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
  puts "#{file_name} writed succesfully"
end

madam_wanted = @max_madam - @present_madam
puts("We found #{madam_wanted} \"Madame\" to download ! !")

(1..madam_wanted).to_a.reverse.each do |n|
  madam_number = @max_madam + 1 - n
  puts "Fetching Madame #{madam_number} on page #{n}"
  picture_link(madam_page(n)) do |link|
    save_in_file madam_number, open(link).read
  end
end


