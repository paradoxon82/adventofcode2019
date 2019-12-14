#!/usr/bin/ruby


class ReactionPart
  attr_reader :name, :count
  def initialize(count, _name)
    @name = _name
    @count = count.to_i
    raise "Seems like #{count} is not a number" if @count == 0
  end

  def to_s
    "name: #{@name}, count #{@count}"
  end
end



class Reaction
  attr_reader :remainder

  def initialize(output, input)
    @output = output
    @input = input
    # remainder from other reactions
    @remainder = 0
  end

  def to_s
    puts "input:"
    @input.each do |inp|
      puts inp
    end
    puts "output: #{@output}"
  end

  def request_output(count)
    #puts "requesting #{count} of #{@output.name}, remainder #{@remainder}"
    request_count = (count - @remainder)
    r = @remainder - count
    @remainder = r > 0 ? r : 0
    #puts "after uning up remainder: #{@remainder}, remaining request: #{request_count}"
    return [] if request_count <= 0
    minimum_reactions = (request_count.to_f / @output.count).ceil
    #puts "minimum_reactions #{minimum_reactions}"
    # save remaining reagenz for later
    @remainder += (minimum_reactions * @output.count) - request_count
    #puts "end: remainder of #{@output.name} is #{@remainder}"
    @input.map do |inp|
      [inp.name, minimum_reactions * inp.count]
    end
  end

end

class ReactionParser
  def initialize
    @reactions = {}
    @ore_name = nil
  end

  def parse(line)
    parts = line.split '=>'
    raise "cannot parse line #{line}" unless parts.size == 2
    react_parts = parts.first.split(',')
    inputs = []
    react_parts.each do |part|
      reagenz = part.strip.split(' ')
      raise "cannot parse reagenz #{reagenz}" unless reagenz.size == 2
      inputs << ReactionPart.new(*reagenz)
    end

    output_parts = parts.last.strip.split(' ')
    raise "cannot parse output #{parts.last}" unless output_parts.size == 2
    output = ReactionPart.new(*output_parts)
    @reactions[output.name] = Reaction.new(output, inputs)
  end

  def get_input_count(output_name, ouput_count)
    raise "No reaction found with product #{output_name}" unless @reactions[output_name]
    end_sum = 0
    end_sum += @reactions[output_name].request_output(ouput_count).map do |input_name, count|
      if input_name == @ore_name
        # end of tree
        #puts "get_input_count: output: #{output_name}, input: #{input_name}, count #{count}"
        count
      else
        get_input_count(input_name, count)
      end
    end.sum
    end_sum
  end

  # how many of input is needed for one output
  def count_input_for(product, ore_name)
    @ore_name = ore_name
    sum = 0
    @reactions[product].request_output(1).each do |input_name_sub, count|
      sum += get_input_count(input_name_sub, count)
    end
    sum
  end

  def remainder
    @reactions.values.map(&:remainder)
  end

  def produce_with(product, ore_name, ore_count)
    @ore_name = ore_name
    sum = 0
    fuel = 0
    start_remainder = nil
    found = false
    while start_remainder != remainder || fuel == 1
      @reactions[product].request_output(1).each do |input_name_sub, count|
        sum += get_input_count(input_name_sub, count)
      end
      fuel += 1
      start_remainder = remainder unless start_remainder
      puts "ore cound #{sum}"
    end
    puts "fuel produced: #{fuel}, remainder: #{remainder}"
    fuel
  end

end

parser = ReactionParser.new
File.foreach(ARGV[0]) do |line|
  next if line.empty?
  parser.parse(line)
end

ore_sum = parser.count_input_for('FUEL', 'ORE')
puts "Sum of ORE input #{ore_sum}"

#ore_count = 1_000_000_000_000
#fuel_sum = parser.produce_with('FUEL', 'ORE', ore_count)
#puts "fuel produced: #{fuel_sum}"
