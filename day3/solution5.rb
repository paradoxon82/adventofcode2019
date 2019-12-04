#!/usr/bin/ruby

class WireParser

  def initialize
    @a_pos = [[0, 0]]
    @b_pos = [[0, 0]]
    @crossovers = []
    @crossovers_with_distances = []
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

  def shorten_line_to(line, end_p)
    [line[0], end_p]
  end

  def shorten_line_from(line, end_p)
    [end_p, line[0]]
  end

  def add_but_check_self_cross(lines, line_to_add)
    last_self_cross = nil
    lines.each_with_index do |l, i|
      if (cross = get_crossover(l, line_to_add))
        last_self_cross = [cross, i]
      end
    end
    if last_self_cross
      cut_at = last_self_cross[1]
      intersection = last_self_cross[0]
      up_to = cut_at - 1
      lines_up_to_self_cross = up_to >= 0 ? lines[0..up_to] : []
      crossed_line = lines[cut_at]
      lines_up_to_self_cross << shorten_line_to(crossed_line, intersection)
      lines_up_to_self_cross << shorten_line_from(line_to_add, intersection)
      lines.replace(lines_up_to_self_cross)
    else
      lines << line_to_add
    end
  end

  def line_length(line)
    (line[0][0] - line[1][0]).abs + (line[0][1] - line[1][1]).abs
  end

  def build_distances(positions)
    lines = []
    positions.each_cons(2) do |line|
      lines << line
      # seems like we do not have to optimize
      #add_but_check_self_cross(lines, line)
    end
    sum = 0
    distances = lines.map do |line|
      tmp = sum
      sum += line_length(line)
      tmp
    end
    [lines, distances]
  end

  def build_both_distances
    @a_line_dist = build_distances(@a_pos)
    @b_line_dist = build_distances(@b_pos)
  end

  def check_crossover2(line_a, line_b, length_up_to_here)
    if (cross = get_crossover(line_a, line_b))
      length_up_to_here += line_length(shorten_line_to(line_a, cross))
      length_up_to_here += line_length(shorten_line_to(line_b, cross))
      @crossovers_with_distances << [length_up_to_here, cross]
    end
  end

  def length_up_to_here(length_a, i_a, length_b, i_b)
    length_a[i_a] + length_b[i_b]
  end

  def check_crossovers2
    build_both_distances()
    @a_line_dist[0].each_with_index do |line_a, i_a|
      @b_line_dist[0].each_with_index do |line_b, i_b|
        length = length_up_to_here(@a_line_dist[1], i_a, @b_line_dist[1], i_b)
        check_crossover2(line_a, line_b, length)
      end
    end
    puts "second crossovers count #{@crossovers_with_distances.size}"
    @crossovers_with_distances.map do |dist_cross|
      dist_cross[0]
    end.min
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

  def print_this(field)
    x_min = field.keys.min
    x_max = field.keys.max
    y_min = nil
    y_max = nil
    #puts field
    field.values.each do |y_vals|
      min = y_vals.keys.min
      max = y_vals.keys.max

      y_min = (y_min.nil? || (y_min > min)) ? min : y_min
      y_max = (y_max.nil? || (y_max < max)) ? max : y_max
    end
    puts "#{x_min} .. #{x_max}"
    puts "#{y_min} .. #{y_max}"

    y_max.downto(y_min).each do |y|
      line = (x_min..x_max).map do |x|
        field[x][y]
      end.join
      puts line
    end
  end

  def add_line_to_field(line, field, direction)
    x_1 = line[0][0]
    x_2 = line[1][0]
    y_1 = line[0][1]
    y_2 = line[1][1]
    [x_1,x_2].min.upto([x_1,x_2].max).each do |x|
      [y_1,y_2].min.upto([y_1,y_2].max).each do |y|
        field[x][y] = direction == :horizontal ? '-' : '|'
      end
    end
  end

  def print_field
    field = Hash.new do |hash, key| 
      hash[key] = Hash.new(' ')
    end
    @a_pos.each_cons(2) do |line|
      add_line_to_field(line, field, get_direction(line))
    end

    @b_pos.each_cons(2) do |line|
      add_line_to_field(line, field, get_direction(line))
    end
    field[0][0] = 'O'

    print_this(field)
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

#parser.print_field

puts "min crossover: #{parser.check_crossovers}"
puts "min crossover: #{parser.check_crossovers2}"
