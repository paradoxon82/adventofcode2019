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
    puts "modes #{modes}"
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
    if count == 3 && modes[3] == 0
      puts 'unexpeced relative jump as assignment'
    end
    operands
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
        # pos1 = codes[pos + 1]
        # pos2 = codes[pos + 2]
        # pos3 = codes[pos + 3]
        # op1 = modes[0].zero? ? codes[pos1] : pos1
        # op2 = modes[1].zero? ? codes[pos2] : pos2
        #puts "op1 #{op1}, op2 #{op2}"
        [4, 3]
      when 3, 4, 9
        # pos1 = codes[pos + 1]
        # pos2 = codes[pos + 2]
        # op1 = modes[0].zero? ? codes[pos1] : pos1
        # op2 = modes[1].zero? ? codes[pos2] : pos2
        [2, 1]
      when 5, 6
        # pos1 = codes[pos + 1]
        # pos2 = codes[pos + 2]
        # op1 = modes[0].zero? ? codes[pos1] : pos1
        # op2 = modes[1].zero? ? codes[pos2] : pos2
        [3, 2]
      else
        raise "unexpeced code #{opcode}"
      end

    puts "operation size #{operation_size}, operand count #{operand_count}"
    ops = modes_to_operands(pos, codes, modes, operand_count)
    puts "ops: #{ops}"
    override_p = nil

    case opcode
    when 1
      codes[ops[2]] = ops[0] + ops[1]
    when 2
      codes[ops[2]] = ops[0] * ops[1]
    when 3
      if input_empty?
        # stay at this position
        @await_input = true
        return pos
      end
      codes[ops[0]] = input_prompt
    when 4
      @last_output = ops[0]
      @output_waiting = true
      puts "output: #{ops[0]}"
    when 5
      override_p = ops[1] if ops[0] != 0
    when 6
      override_p = ops[1] if ops[0] == 0
    when 7
      codes[ops[2]] = (ops[0] < ops[1]) ? 1 : 0
    when 8
      codes[ops[2]] = (ops[0] == ops[1]) ? 1 : 0
    when 9
      @relative_base += ops[0]
    end

    return override_p if override_p

    pos + operation_size
  end
end

class Amplifier
  attr_accessor :next_amp
  attr_reader :opcodes, :parser, :name, :it_count

  def initialize(_name, opcodes, phase_signal)
    @name = _name
    @opcodes = opcodes
    @parser = OpcodeParser.new(phase_signal)
    @position = 0
    @it_count = 0
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
    puts "iteration #{it_count} of #{name} starting at #{@position}"
    while parser.can_continue?
      puts "position #{@position}"
      next_pos = parser.parse(@position, opcodes)
      #puts "next pos #{next_pos}"
      forward_output
      @position = next_pos
    end
    next_iteration
    parser.last_output
  end

  def add_input(input)
    parser.add_input(input)
  end

  def forward_output
    return unless next_amp

    if (output = parser.acquire_output)
      puts "sending #{output} to #{next_amp.name}"
      next_amp.add_input(output)
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

opt = Amplifier.new('A', op_hash, 1)
puts "BOOST keycode: #{opt.iteration}"
