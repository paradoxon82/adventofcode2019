#!/usr/bin/ruby

list = []
File.open(ARGV[0], "r") do |file|  
  while !file.eof?
    list << file.readline.strip
  end
end

def calc_fuel(item)
  fuel = (item.to_i / 3) - 2
  fuel > 0 ? fuel : 0
end

def calc_fuel_complete(mass)
  sum = 0
  while (added = calc_fuel(mass)) > 0
    sum += added
    mass = added
  end  
  sum
end

sum = 0
sum2 = 0
list.each do |item|
  sum += calc_fuel(item)
  sum2 += calc_fuel_complete(item)
end

puts "fuel part 1: #{sum}" 
puts "fuel part 2: #{sum2}"