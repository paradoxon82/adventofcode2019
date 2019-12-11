#!/usr/bin/ruby

class OpcodeParser
  attr_reader :last_output, :mode, :relative_base
  attr_accessor :input_values

  def initialize(phase)
    @halt = false
    @input_values = [phase]
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

  def can_continue?
    !@await_input && !halt?
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
      puts "output: #{ops[0]}"
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

class RobotBrain
  attr_accessor :next_amp
  attr_reader :opcodes, :parser, :name, :it_count

  def initialize(_name, opcodes, phase_signal)
    @name = _name
    @opcodes = opcodes
    @parser = OpcodeParser.new(phase_signal)
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

  def iteration
    clear_output
    puts "iteration #{it_count} of #{name} starting at #{@position}"
    while parser.can_continue?
      #puts "position #{@position}"
      next_pos = parser.parse(@position, opcodes)
      #puts "next pos #{next_pos}"
      record_output
      @position = next_pos
    end
    next_iteration
    all_outputs
  end

  def add_input(input)
    parser.add_input(input)
  end

  def clear_output
    @output_values.clear
  end

  def record_output
    if (output = parser.acquire_output)
      puts "saving #{output}"
      @output_values << output
    end
  end

  def all_outputs
    @output_values
  end

end

class Robot
  def initialize(opcodes)
    @brain = RobotBrain.new('Brain', opcodes, 0)
    @hull = Hash.new { |hash, key| hash[key] = 0 }
    @position = [0, 0]
    @orientations = [:up, :left, :down, :right]
  end

  def paint(val)
    @hull[@position] = val
  end

  def current_color
    @hull[@position]
  end

  def current_orientation
    @orientations.first
  end

  def next_orientation(direction)
    case direction
    when :left
      @orientations.rotate!(1)
    when :right
      @orientations.rotate!(-1)
    else
      raise "unknown direction #{direction}"
    end
  end

  def move_one
    case current_orientation
    when :up
      @position[1] +=1
    when :down
      @position[1] -=1
    when :left
      @position[0] -=1
    when :right
      @position[0] +=1
    else
      raise "current_orientation unknown!"
    end
  end

  def move(val)
    case val
    when 0
      next_orientation(:left)
      move_one()
    when 1
      next_orientation(:right)
      move_one()
    else
      raise "unrecognized move code #{val}"
    end
        
  end

  def paint_all
    until @brain.halt?
      values = @brain.iteration
      raise "unexpeced return value count: #{values}, expected exactly two values!" if values.size != 2
      paint(values[0])
      move(values[1])
      @brain.add_input(current_color)
    end
    @hull.keys.size
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

opt = Robot.new(op_hash)
puts "painted tiles: #{opt.paint_all}"

