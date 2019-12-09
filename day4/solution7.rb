#!/usr/bin/ruby

class PassChecker
  def self.is_valid?(number)
    digits = number.to_s.chars.map(&:to_i)
    has_doubles = false
    increasing = true
    digits.each_cons(2) do |pair|
      increasing = false if pair[1] < pair[0]
      has_doubles = true if pair[0] == pair[1]
    end
    has_doubles && increasing
  end

  def self.repeat_count_twos(digits)
    last = digits.first
    repeats = []
    repeat = 1
    digits[1..-1].each do |i|
      if i == last
        repeat += 1
      else
        repeats << repeat if repeat > 1
        last = i
        repeat = 1
      end
    end
    repeats << repeat if repeat > 1
    # have only repeats of size 2
    repeats.member?(2)
  end

  def self.is_valid2?(number)
    digits = number.to_s.chars.map(&:to_i)
    increasing = true
    digits.each_cons(2) do |pair|
      increasing = false if pair[1] < pair[0]
    end
    
    increasing && repeat_count_twos(digits)
  end
end

#puts "is valid: #{PassChecker.is_valid?(111111)}"

valid_count = (124_075..580_769).count do |number|
  PassChecker.is_valid?(number)
end

puts "valid count: #{valid_count}"

valid_count = (124_075..580_769).count do |number|
  PassChecker.is_valid2?(number)
end

puts "valid count2: #{valid_count}"
