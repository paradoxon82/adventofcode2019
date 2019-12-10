#!/usr/bin/ruby
require 'set'

class LineOfSight

  def self.range(up_until)
    if up_until < 0
      ((up_until + 1)..-1)
    else
      (1..(up_until - 1))
    end
  end

  # get all positions between a and b that are on the grid (not fractions)
  def self.positions_between(a, b)
    dx = b[0] - a[0]
    dy = b[1] - a[1]
    return [] if dx == 0 && dy == 0
    positions = []
    
    if dy == 0
      range(dx).map do |dx_i|
        [a[0] + dx_i, a[1]]
      end
    elsif dx == 0
      range(dy).map do |dy_i|
        [a[0], a[1] + dy_i]
      end
    elsif (dx.abs > dy.abs)
      #more horizontal
      r = Rational(dy, dx)
      range(dx).map do |dx_i|
        dy_i = r * dx_i
        [a[0] + dx_i, a[1] + dy_i.to_i] if dy_i.denominator == 1
      end
    else
      r = Rational(dx, dy)
      range(dy).map do |dy_i|
        dx_i = r * dy_i
        [a[0] + dx_i.to_i, a[1] + dy_i] if dx_i.denominator == 1
      end
    end
  end

  def self.angle(a, b)
    dx = b[0] - a[0]
    dy = b[1] - a[1]
    rad = Math.atan2(dx, -dy)
    
    rad = Math::PI + (Math::PI + rad) if rad < 0

    rad
  end
end

class StarfieldBuilder

  def initialize
    @asteroids = Set.new
  end

  def calc_max
    @max_x = @asteroids.max_by(&:first).first
    @max_y = @asteroids.max_by(&:last).last
  end

  def add_line(line, current_y)
    line.strip.chars.each_with_index do |position, x|
      if position == '#'
        @asteroids << [x, current_y]
      end
    end
  end

  def collect_observations(vantage)
    obs = @asteroids.clone.to_set
    obs.delete(vantage)
    @asteroids.each do |ast|
      pos_list = LineOfSight.positions_between(vantage, ast)
      obstructions = obs & pos_list
      #remove asteroid if its obstructed by others
      obs.delete(ast) unless obstructions.empty?
    end
    #puts "vantage: #{vantage}, observations #{obs.size}"
    obs
  end

  def best_observation
    calc_max
    observations = {}
    @asteroids.each do |vantage|
      observations[vantage] = collect_observations(vantage)
    end

    vantage, obervations = observations.max_by { |vantage, obs| obs.size }
  end

  def vaporize(ast)
    @asteroids.delete(ast)
  end

  def vaporize_asteroids(station, stop_at)
    last_end = 1
    matching_asteroid = nil
    while (reachable_asteroids = collect_observations(station)).any?
      reachable_asteroids.sort_by do |asteroid|
        LineOfSight.angle(station, asteroid)
      end.each_with_index do |ast, i|
        puts "vaporizing #{i + last_end}: #{ast.join(', ')}"
        vaporize(ast)
        matching_asteroid = ast if (i + last_end) == stop_at
      end
      last_end += reachable_asteroids.size
    end
    matching_asteroid
  end
end

builder = StarfieldBuilder.new
y = 0
File.foreach(ARGV[0]) do |line|
  next if line.empty?

  builder.add_line(line, y)
  y += 1
end

vantage, observations = builder.best_observation
puts "observed from #{vantage.join(', ')} - asteroids: #{observations.size}"
matching = builder.vaporize_asteroids(vantage, 200)
puts "matching #{matching[0]*100 + matching[1]}"
