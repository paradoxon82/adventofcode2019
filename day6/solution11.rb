#!/usr/bin/ruby

class Orbit

  attr_reader :depth, :name

  def initialize(_name)
    @name = _name
    @children = []
    @names_found = {}
    @depth = nil
  end

  def found_child?(_name)
    @names_found[_name]
  end 

  def descend(depth = 0)
    sum = depth
    @depth = depth
    @children.each do |child|
      sum += child.descend(depth + 1)
    end
    sum
  end

  def descend_to(_name, depth = 0)
    return true if _name == @name
      
    @names_found[_name] = @children.any? do |child|
      child.descend_to(_name, depth + 1)
    end
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
    unless @orbits[outer]
      @orbits[outer] = Orbit.new(outer)
    end
    # TODO check if loops exist
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

  def calculate_travel
    raise 'SAN not found!' unless @orbits['SAN']
    raise 'YOU not found!' unless @orbits['YOU']
    @orbits['COM'].descend_to('SAN')
    @orbits['COM'].descend_to('YOU')
    orbits_reachable = @orbits.values.select do |orbit|
      orbit.found_child?('SAN') && orbit.found_child?('YOU')
    end
    orbit = orbits_reachable.max_by do |orbit|
      orbit.depth
    end
    puts "SAN depth #{@orbits['SAN'].depth}"
    puts "YOU depth #{@orbits['YOU'].depth}"
    puts "intersection depth #{orbit.depth}"
    branch_a = @orbits['SAN'].depth - orbit.depth - 1
    branch_b = @orbits['YOU'].depth - orbit.depth - 1
    branch_a + branch_b
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
puts "travel steps: #{builder.calculate_travel}"