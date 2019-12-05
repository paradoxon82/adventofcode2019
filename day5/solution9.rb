#!/usr/bin/ruby

class OpcodeParser

  def self.split_input(input)
    if input.size == 1
      opcode = input.to_i
    else
      opcode = input[-2..-1].to_i
    end
    modes = [0, 0, 0] # default of 0
    input[0..-3].chars.reverse.each_with_index do |val, i|
      modes[i] = val.to_i
      raise "unexpeced mode #{val} at position #{i}" if modes[i] != 0 && modes[i] != 1
    end

    [opcode, modes]
  end

  def self.input_prompt
    puts 'input:'
    STDIN.gets.chomp
  end

  def self.parse(pos, codes)
    input = codes[pos].to_s

    #puts "input #{input} at #{pos}"

    opcode, modes = split_input(input)
    #puts "opcode #{opcode}"
    #puts "modes #{modes}"

    return -1 if opcode == 99

    pos1 = pos2 = pos3 = nil
    op1 = op2 = nil
    op_count =
      case opcode
      when 1, 2
        pos1 = codes[pos + 1]
        pos2 = codes[pos + 2]
        pos3 = codes[pos + 3]
        op1 = modes[0].zero? ? codes[pos1] : pos1
        op2 = modes[1].zero? ? codes[pos2] : pos2
        #puts "op1 #{op1}, op2 #{op2}"
        3
      when 3, 4
        pos1 = codes[pos + 1]
        1
      else
        raise "unexpeced code #{opcode}"
      end

    case opcode
    when 1
      codes[pos3] = op1 + op2
    when 2
      codes[pos3] = op1 * op2
    when 3
      codes[pos1] = input_prompt.to_i
    when 4
      puts "output: #{codes[pos1]}"
    end

    pos + op_count + 1
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

pos = 0
while (next_pos = OpcodeParser.parse(pos, opcodes)) != -1
  puts "next pos #{next_pos}"
  pos = next_pos
end
