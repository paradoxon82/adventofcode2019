#!/usr/bin/ruby

class OpcodeParser

  def self.parse(pos, codes)
    if codes[pos] == 99
      puts "Programm exited with #{codes[0]} at pos 0"
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

end

if ARGV.size == 0
  puts "no input file!"
  return
end

opcodes = []
File.foreach(ARGV[0]) do |line|
  opcodes.concat(line.strip.split(',').map(&:to_i))
end

opcodes[1] = 12
opcodes[2] = 2

pos = 0
while (next_pos = OpcodeParser.parse(pos, opcodes)) != -1
  puts "next pos #{next_pos}"
  pos = next_pos
end

