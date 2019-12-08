#!/usr/bin/ruby

class ImageParser

  def initialize
    @height = 6
    @width = 25
    @layers = []
    @image = Array.new(6) { |i| Array.new(25) }
  end

  def parse_input(chars)
    @layers = chars.map(&:to_i).each_slice(25*6).map
  end

  def place_pixels
    @layers.each do |layer|
      i = 0
      (0...@height).each do |y|
        (0...@width).each do |x|
          if layer[i] != 2
            # only set the pixel if empty
            @image[y][x] = layer[i] unless @image[y][x]
          end
          i += 1
        end
      end
    end
  end

  def show_image
    place_pixels
    @image.each do |row|
      pixels = row.map { |e| e != 0 ? 'X' : ' ' }
      puts pixels.join
    end
  end

  def layer_with_fewest_zeroes
    @layers.min_by do |layer|
      number_of_digits(layer, 0)
    end
  end

  def number_of_digits(layer, digit)
    layer.count {|pixel| pixel == digit }
  end

  def calculate
    layer = layer_with_fewest_zeroes
    number_of_digits(layer, 1) * number_of_digits(layer, 2)
  end
end

parser = ImageParser.new

input = []
File.foreach(ARGV[0]) do |line|
  input += line.strip.chars
end

parser.parse_input(input)
puts "calculation: #{parser.calculate}"
puts "decoded image:"
parser.show_image