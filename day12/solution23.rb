#!/usr/bin/ruby

module Energy
  attr_accessor :x, :y, :z
  def energy
    x.abs + y.abs + z.abs
  end
end

class Velocity
  include Energy
  def initialize(x = 0, y = 0, z = 0)
    @x = x
    @y = y
    @z = z
  end

  def +(other)
    Velocity.new(x + other.x, y + other.y, z + other.z)
  end
end

class Position 
  include Energy
  def initialize(x = 0, y = 0, z = 0)
    @x = x
    @y = y
    @z = z
  end

  def diff(a, b)
    -(a <=> b)
  end

  def calc_velo(other)
    dx = diff(x, other.x)
    dy = diff(y, other.y)
    dz = diff(z, other.z)
    Velocity.new(dx, dy, dz)
  end

  def add_velo(v)
    #puts "add_velo"
    #puts "#{x} : #{y} : #{z}"
    #puts "#{v.x} : #{v.y} : #{v.z}"
    self.x += v.x
    self.y += v.y
    self.z += v.z
    #puts "#{x} : #{y} : #{z}"
  end

end

class Moon
  attr_accessor :velocity, :position

  def initialize(position, velocity = nil)
    @position = position
    @velocity = velocity.nil? ? Velocity.new : velocity
  end

  def apply_velocity
    @position.add_velo(@velocity)
  end

  def calculate_velocity(other)
    @velocity += position.calc_velo(other.position)
  end

  def self.parse(line)
    m = line.match(/<x=(-?\d+), y=(-?\d+), z=(-?\d+)>/)
    raise "Unable to parse line #{line}" unless m
    Moon.new(Position.new(m[1].to_i, m[2].to_i, m[3].to_i))
  end

  def potential_e
    @position.energy
  end

  def kinetic_e
    @velocity.energy
  end

  def total_e
    potential_e * kinetic_e
  end

  def clone
    Moon.new(@position.clone, velocity.clone)
  end

end

class OrbitKeeper

  def initialize
    @moons = []
  end

  def add_moon(moon)
    @moons << moon
  end

  def gravity(m1, m2)
    m1.calculate_velocity(m2)
    m2.calculate_velocity(m1)
  end

  def velocity(m)
    m.apply_velocity
  end

  def calculate_orbits(steps)
    steps.times do |step|
      iterate_orbits
    end
  end

  def axis_status(axis)
    @moons.map(&:position).map {|m| m.send(axis)} + @moons.map(&:velocity).map {|m| m.send(axis)}
  end

  def iterate_orbits
    @moons.combination(2) do |m1, m2|
      gravity(m1, m2)
    end
    @moons.each do |m|
      velocity(m)
    end
  end

  def calculate_interval(axis)
    start_val = axis_status(axis)
    iteration = 0
    loop do
      iterate_orbits
      iteration += 1
      break if start_val == axis_status(axis)
    end
    iteration
  end

  def calculate_until_repeat
    interval_x = calculate_interval(:x)
    puts "interval x #{interval_x}" 
    interval_y = calculate_interval(:y)
    puts "interval y #{interval_y}" 
    interval_z = calculate_interval(:z)
    puts "interval z #{interval_z}" 
    first = interval_x.lcm(interval_y)
    first.lcm(interval_z)
  end

  def total_energy
    @moons.map(&:total_e).reduce(&:+)
  end
end

if ARGV.size == 0
  puts 'no input file!'
  return
end

moves = OrbitKeeper.new
File.foreach(ARGV[0]) do |line|
  next if line.empty?
  moves.add_moon(Moon.parse(line))
end
moves.calculate_orbits(1000)
puts "total energy: #{moves.total_energy}"
puts "repeating orbits at: #{moves.calculate_until_repeat()}"
