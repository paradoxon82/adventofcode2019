#!/usr/bin/ruby

class WireParser

  def initialize
    @a_pos = [[0, 0]]
    @b_pos = [[0, 0]]
    @crossovers = []
  end

  def add_direction_a(direction)
    add_direction(direction, @a_pos)
  end

  def add_direction_b(direction)
    add_direction(direction, @b_pos)
  end

  def add_direction(direction, pos_list)
    diff = parse_direction(direction)
    pos = pos_list.last.clone
    pos[0] += diff[0]
    pos[1] += diff[1]
    pos_list << pos
  end

  def parse_direction(direction)
    start = direction[0]
    amount = direction[1..-1].to_i
    case start
    when 'U'
      [0, amount]
    when 'D'
      [0, -amount]
    when 'L'
      [-amount, 0]
    when 'R'
      [amount, 0]
    end
  end

  def get_direction(line)
    if line[0][0] != line[1][0]
      :horizontal
    elsif line[0][1] != line[1][1]
      :vertical
    else
      raise "line not recogized: #{line}"
    end

  end

  def intersect_range(from, to, point)
    if from > to
      tmp = to
      to = from
      from = tmp
    end
    #puts "intersect: #{from} - #{to}" if (point > from) && (point < to)
    point if (point > from) && (point < to)
  end

  # horizontal to vetical intersection
  def intersect_h_to_v(h, v) 
    i_x = intersect_range(h[0][0], h[1][0], v[0][0]) # get x of intersection
    i_y = intersect_range(v[0][1], v[1][1], h[0][1]) # get y of intersection
    [i_x, i_y] if i_x && i_y
  end

  def intersect(line_a, line_b)
    if get_direction(line_a) == :horizontal
      intersect_h_to_v(line_a, line_b)
    elsif get_direction(line_b) == :horizontal
      intersect_h_to_v(line_b, line_a)
    else
      raise 'unmatching intersection'
    end
  end

  def get_crossover(line_a, line_b)
    if get_direction(line_a) != get_direction(line_b)
      intersect(line_a, line_b)
    end
  end

  def check_crossover(line_a, line_b)
    if (cross = get_crossover(line_a, line_b))
      @crossovers << cross
    end
  end

  def distance(cross)
    cross[0].abs + cross[1].abs
  end

  def check_crossovers
    @a_pos.each_cons(2) do |line_a|
      @b_pos.each_cons(2) do |line_b|
        check_crossover(line_a, line_b)
      end
    end
    puts "crossovers count #{@crossovers.size}"
    @crossovers.map do |cross|
      distance(cross)
    end.min
  end
end

if ARGV.size.zero?
  puts 'no input file!'
  return
end

directions = []
File.foreach(ARGV[0]) do |line|
  directions << line.strip.split(',')
end

if directions.size != 2
  puts "too many input lines: #{directions.size}!"
  return -1
end

parser = WireParser.new

directions[0].each do |dir|
  parser.add_direction_a(dir)
end

directions[1].each do |dir|
  parser.add_direction_b(dir)
end

puts "min crossover: #{parser.check_crossovers}"
