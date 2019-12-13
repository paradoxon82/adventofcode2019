#!/usr/bin/ruby

require 'io/console'

class OpcodeParser
  attr_reader :last_output, :mode, :relative_base
  attr_accessor :input_values

  def initialize(phase = nil)
    @halt = false
    @input_values = []
    @input_values << phase if phase
    @relative_base = 0
    @last_output = nil
    @output_waiting = false
    @await_input = false
  end

  # return last ouput if it was not yet acquired
  def acquire_output
    return nil unless @output_waiting

    @output_waiting = false
    @last_output
  end

  def valid_modes
    [0, 1, 2]
  end

  def split_input(input)
    opcode = if input.size == 1
      input.to_i
    else
      input[-2..-1].to_i
    end
    modes = [0, 0, 0] # default of 0
    input[0..-3].chars.map(&:to_i).reverse.each_with_index do |val, i|
      modes[i] = val
      #raise "input: #{input} - unexpeced mode #{val} at position #{i}" unless valid_modes.member?(val)
    end

    [opcode, modes]
  end

  def halt?
    @halt
  end

  def await_input?
    @await_input
  end

  def can_continue?
    !await_input? && !halt?
  end

  def input_empty?
    @input_values.empty?
  end

  def input_prompt
    raise 'no more input available!' if input_empty?

    @input_values.shift
  end

  def add_input(input)
    @input_values << input
    @await_input = false
  end

  def modes_to_operands(pos, codes, modes, count)
    #puts "modes #{modes}"
    operands = Array.new(count)
    (0...count).each do |i|
      val = codes[pos + i + 1]
      case modes[i]
      when 0
        operands[i] = codes[val]
      when 1
        operands[i] = val
      when 2
        operands[i] = codes[relative_base + val]
      else
        raise "unknown mode #{modes[i]}"
      end
    end
    operands
  end

  def save_result(result, pos, res_pos, modes, codes)
    val = codes[pos + res_pos + 1]
    save_position =
      case modes[res_pos]
      when 0
        val
      when 1
        raise 'unrecognized mode 1 for result storage'
      when 2
        relative_base + val
      end
    codes[save_position] = result
  end

  def parse(pos, codes)
    input = codes[pos].to_s

    #puts "input #{input} at #{pos}"

    opcode, modes = split_input(input)
    # puts "opcode #{opcode}"
    # puts "modes #{modes}"

    if opcode == 99
      @halt = true
      return -1
    end

    operation_size, operand_count =
      case opcode
      when 1, 2, 7, 8
        [4, 3]
      when 3, 4, 9
        [2, 1]
      when 5, 6
        [3, 2]
      else
        raise "unexpeced code #{opcode}"
      end

    #puts "operation size #{operation_size}, operand count #{operand_count}"
    ops = modes_to_operands(pos, codes, modes, operand_count)
    #puts "ops: #{ops}"
    override_p = nil

    result = nil
    res_pos = nil
    case opcode
    when 1
      res_pos = 2
      result = ops[0] + ops[1]
    when 2
      res_pos = 2
      result = ops[0] * ops[1]
    when 3
      if input_empty?
        # stay at this position
        @await_input = true
        return pos
      end
      res_pos = 0
      result = input_prompt
    when 4
      @last_output = ops[0]
      @output_waiting = true
      #puts "output: #{ops[0]}"
    when 5
      override_p = ops[1] if ops[0] != 0
    when 6
      override_p = ops[1] if ops[0] == 0
    when 7
      res_pos = 2
      result = (ops[0] < ops[1]) ? 1 : 0
    when 8
      res_pos = 2
      result = (ops[0] == ops[1]) ? 1 : 0
    when 9
      @relative_base += ops[0]
    end

    save_result(result, pos, res_pos, modes, codes) if result && res_pos

    return override_p if override_p

    pos + operation_size
  end
end

class Arcade
  attr_accessor :next_amp
  attr_reader :opcodes, :parser, :name, :it_count

  def initialize(_name, opcodes)
    @name = _name
    @opcodes = opcodes
    @parser = OpcodeParser.new()
    @position = 0
    @it_count = 0
    @output_values = []
  end

  def next_iteration
    @it_count += 1
  end

  def halt?
    parser.halt?
  end

  def last_output
    parser.last_output
  end

  def key_to_direction(char)
    case char
    when 'a'
      -1
    when 's'
      0
    when 'd'
      1
    else
      nil
    end
  end

  def provide_joystick
    dir = nil
    while dir.nil?
      dir = key_to_direction(STDIN.getch)
    end
    add_input(dir)
  end

  def iteration
    #clear_output
    end_loop = false
    #puts "iteration #{it_count} of #{name} starting at #{@position}"
    while parser.can_continue?
      #puts "position #{@position}"
      next_pos = parser.parse(@position, opcodes)
      #puts "next pos #{next_pos}"

      record_output
      @position = next_pos

      break if end_loop      
      if parser.await_input?
        puts "move?"
        provide_joystick
        end_loop = true
      end
    end
    next_iteration
    all_outputs
  end

  def add_input(input)
    puts "add input #{input}"
    parser.add_input(input)
  end

  def clear_output
    @output_values.clear
  end

  def record_output
    if (output = parser.acquire_output)
      #puts "saving #{output}"
      @output_values << output
    end
  end

  def all_outputs
    @output_values
  end

end

class ArcadeSetup
  def initialize(opcodes, game = false)
    opcodes = opcodes.clone
    opcodes[0] = 2 if game
    @brain = Arcade.new('Brain', opcodes)
    @field = Hash.new { |hash, key| hash[key] = 0 }
    @score = 0
  end

  def paint(x, y, val)
    if (x == -1 &&  y == 0)
      @score = val
    else
      @field[[x,y]] = val
    end
  end

  def to_symbol(val)
    case val
    when 0
      ' '
    when 1
      '|'
    when 2
      '#'
    when 3
      '-'
    when 4
      '*'
    else
      raise "unknow symbos #{val}"
    end
  end

  def print_picture

    puts "score: #{@score}"
    #puts "keys: #{@field.keys}"
    min_x = @field.keys.min_by(&:first).first
    max_x = @field.keys.max_by(&:first).first
    min_y = @field.keys.min_by(&:last).last
    max_y = @field.keys.max_by(&:last).last
#    puts "min_x #{min_x}"
#    puts "max_x #{max_x}"
#    puts "min_y #{min_y}"
#    puts "max_y #{max_y}"
    #exit 0
    (min_y..max_y).each do |y|
      row = (min_x..max_x).map do |x|
        to_symbol(@field[[x, y]])
      end
      puts row.join
    end
  end

  def iterate_and_print
    outputs = @brain.iteration
    outputs.each_slice(3) do |slice|
      paint(*slice)
    end
    print_picture
  end

  def count_blocks
    iterate_and_print
    @field.values.count {|val| val == 2}
  end

  def play_game
    while !@brain.halt?
      iterate_and_print
    end
  end
end


if ARGV.size == 0
  puts 'no input file!'
  return
end


opcodes = []
File.foreach(ARGV[0]) do |line|
  next if line.empty?
  opcodes.concat(line.strip.split(',').map(&:to_i))
end

# create an index based hash that returns zero when there is no element yet at this position
op_hash =  Hash.new(0).merge(Hash[(0...opcodes.size).zip opcodes])

opt = ArcadeSetup.new(op_hash)
puts "block tiles: #{opt.count_blocks}"
opt = ArcadeSetup.new(op_hash, true)
opt.play_game
