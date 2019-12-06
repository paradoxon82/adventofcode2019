#!/usr/bin/ruby

class Orbit

  def initialize(name)
    @children = []
  end

  def descend(depth = 0)
    sum = depth
    @children.each do |child|
      sum += child.descend(depth + 1)
    end
    sum
  end

  def add_child(outer)
    @children << outer
  end

end

class OrbitBuilder

  def initialize
    @orbits = {}
  end

  def add_orbit(inner, outer)
    unless @orbits[inner]
      @orbits[inner] = Orbit.new(inner)
    end
    raise "orbit of #{outer} already registered!" if @orbits[outer]
    @orbits[outer] = Orbit.new(outer)
    @orbits[inner].add_child(@orbits[outer])
  end

  def parse_line(line)
    parts = line.strip.split(')')
    raise "unparsable #{line}" if parts.size != 2

    add_orbit(parts[0], parts[1])
  end

  def calculate_orbit_count
    raise 'COM not found!' unless @orbits['COM']
    @orbits['COM'].descend
  end
end

if ARGV.size == 0
  puts "no input file!"
  return
end

builder = OrbitBuilder.new

File.foreach(ARGV[0]) do |line|
  next if line.empty?
  builder.parse_line(line)
end

puts "orbit count: #{builder.calculate_orbit_count}"