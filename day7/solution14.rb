#!/usr/bin/ruby

class OpcodeParser
  attr_reader :last_output, :mode
  attr_accessor :input_values

  def initialize(phase)
    @halt = false
    @input_values = [phase]
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

  def split_input(input)
    if input.size == 1
      opcode = input.to_i
    else
      opcode = input[-2..-1].to_i
    end
    modes = [0, 0, 0] # default of 0
    input[0..-3].chars.reverse.each_with_index do |val, i|
      modes[i] = val.to_i
      raise "input: #{input} - unexpeced mode #{val} at position #{i}" if modes[i] != 0 && modes[i] != 1
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

  def parse(pos, codes)
    input = codes[pos].to_s

    #puts "input #{input} at #{pos}"

    opcode, modes = split_input(input)
    #puts "opcode #{opcode}"
    #puts "modes #{modes}"

    if opcode == 99
      @halt = true
      return -1
    end

    pos1 = pos2 = pos3 = nil
    op1 = op2 = nil
    op_count =
      case opcode
      when 1, 2, 7, 8
        pos1 = codes[pos + 1]
        pos2 = codes[pos + 2]
        pos3 = codes[pos + 3]
        op1 = modes[0].zero? ? codes[pos1] : pos1
        op2 = modes[1].zero? ? codes[pos2] : pos2
        #puts "op1 #{op1}, op2 #{op2}"
        3
      when 3, 4
        pos1 = codes[pos + 1]
        pos2 = codes[pos + 2]
        op1 = modes[0].zero? ? codes[pos1] : pos1
        op2 = modes[1].zero? ? codes[pos2] : pos2
        1
      when 5, 6
        pos1 = codes[pos + 1]
        pos2 = codes[pos + 2]
        op1 = modes[0].zero? ? codes[pos1] : pos1
        op2 = modes[1].zero? ? codes[pos2] : pos2
        2
      else
        raise "unexpeced code #{opcode}"
      end

    override_p = nil

    case opcode
    when 1
      codes[pos3] = op1 + op2
    when 2
      codes[pos3] = op1 * op2
    when 3
      if input_empty?
        # stay at this position
        @await_input = true
        return pos
      end
      codes[pos1] = input_prompt
    when 4
      @last_output = op1
      @output_waiting = true
      puts "output: #{op1}"
    when 5
      override_p = op2 if op1 != 0
    when 6
      override_p = op2 if op1 == 0
    when 7
      codes[pos3] = (op1 < op2) ? 1 : 0
    when 8
      codes[pos3] = (op1 == op2) ? 1 : 0
    end

    return override_p if override_p
    pos + op_count + 1
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
    if output = parser.acquire_output
      puts "sending #{output} to #{next_amp.name}"
      next_amp.add_input(output) 
    end
  end

end

class AmpOptimizer
  def initialize(opcodes)
    @opcodes = opcodes
  end

  def names 
    ['A', 'B', 'C', 'D', 'E']
  end

  def create_amplifiers(phase_values)
    amps = phase_values.each_with_index.map do |phase_signal, i|
      Amplifier.new(names[i], @opcodes, phase_signal)
      #puts "amplifiction out #{out}, using phase #{phase_signal} and in #{input}"
    end
    # connect the amplifiers in circle 
    amps.each_cons(2) do |amp1, amp2|
      amp1.next_amp = amp2
    end
    amps.last.next_amp = amps.first
    # initial input
    amps.first.add_input(0)
    amps
  end

  def iteration(amps)
    amps.each do |amp|
      amp.iteration
    end
  end

  def not_halted?(amps)
    amps.none? do |amp|
      amp.halt?
    end
  end

  # outpus of the end of the feedback loop
  def last_output(amps)
    amps.last.last_output
  end

  def check_amplification(phase_values)
    puts "checking amplifiction with #{phase_values}"
    amps = create_amplifiers(phase_values)
    while not_halted?(amps)
      iteration(amps)
    end
    last_output(amps)
  end

  def find_max_output
    output = 0
    code = nil
    (5..9).to_a.permutation.each do |a|
      o = check_amplification(a)
      if o > output
        output = o
        code = a
      end
    end
    [output, code]
  end
end

if ARGV.size == 0
  puts "no input file!"
  return
end


opcodes = []
File.foreach(ARGV[0]) do |line|
  next if line.empty?
  opcodes.concat(line.strip.split(',').map(&:to_i))
end

opt = AmpOptimizer.new(opcodes)
output, code = opt.find_max_output
puts "output: #{output}"
puts "code: #{code}"
