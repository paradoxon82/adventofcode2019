#!/usr/bin/ruby

class OpcodeParser

  def self.parse(pos, codes)
    if codes[pos] == 99
      return -1
    end

    pos1 = codes[pos+1]
    pos2 = codes[pos+2]
    ret_pos = codes[pos+3]

    result = case codes[pos]
    when 1
      codes[pos1] + codes[pos2]
    when 2
      codes[pos1] * codes[pos2]
    else
      raise "unexpeced code #{codes[pos]}"
    end

    codes[ret_pos] = result
    
    return pos+4
  end

  def self.iteration(input, noun, verb)
    opcodes = input.clone
    opcodes[1] = noun
    opcodes[2] = verb

    pos = 0
    while (next_pos = parse(pos, opcodes)) != -1
      pos = next_pos
    end
    opcodes[0]
  end

end

if ARGV.size == 0
  puts "no input file!"
  return
end

opcodes = []
File.foreach(ARGV[0]) do |line|
  opcodes.concat(line.strip.split(',').map(&:to_i))
end

initial_state = opcodes.clone

opcodes[1] = 12
opcodes[2] = 2

pos = 0
while (next_pos = OpcodeParser.parse(pos, opcodes)) != -1
  puts "next pos #{next_pos}"
  pos = next_pos
end
puts "Programm exited with #{opcodes[0]} at pos 0"

(0..99).each do |noun|
  (0..99).each do |verb|
    result = OpcodeParser.iteration(initial_state, noun, verb)
    if result == 19690720
      puts "verb #{verb} - noun #{noun}"
      puts "solution: #{100*noun + verb}"
      exit 0
    end
  end
end

puts "no combination found for verb and noun to produce 19690720"

