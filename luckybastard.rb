#!/usr/bin/env ruby
require 'securerandom'
require 'money-tree'
require 'open-uri'
require 'colorize'
require 'net/http'

class LuckyBastard

  LIST = false.freeze
  SEED = "path_to_file.txt".freeze
  
  def self.start!(max_sleep = 2, type = :sent)
    LuckyBastard.new(max_sleep, type).start
  end

  def initialize(max_sleep = 2, type = :sent)
    @counter = 0
    @count   = 0
    @type    = type
    @paused  = false
    @pause   = max_sleep
    @start   = Time.now.to_i
    load_seed_list if LIST == true
  end

  def pause=(max_sleep)
    @pause = max_sleep
  end

  def pause
    @pause
  end

  def pause?
    @paused
  end

  def pause!
    if pause? then start else stop end
  end

  def stop
    @pause = true
  end

  def start
    pause! if pause?
    until pause? do execute end      
  end

  private

  def execute
    generate_private_key!
    check @address
    @count += 1
    if @balance > 0.0
      @end = Time.now.to_i - @start
      write_to_file(@address, @balance, @seed)
      puts "[*] Valid seed found in #{(@end / 60)} minutes".yellow
      puts "[!] Enter 'Q' to quit, or any key to continue (q/Q):".yellow
      answer = STDIN.gets.chomp
      %w[q Q].include?(answer) ? exit(1) : start
    elsif @count >= 10
      @counter += @count
      system 'clear' or system 'cls'
      print "\n >> Looking for [".green + "#{@type.to_s.upcase}".yellow + "]".green
      puts " coins on random address".green
      puts "\n " +" #{@counter} ".black.on_yellow + " random seeds checked...".yellow
      puts ""
      write_to_file(@address, @balance, @seed, save: false)
      @count = 0
      sleep rand(pause)
    end
  end

  def generate_private_key( from_list = LIST )
    if from_list == true
      @seed = @seeds[(@seed_count += 1).pred]
      @address  = MoneyTree::Master.new(seed_raw: @hex_seed).to_address
    else
      @seed = SecureRandom.hex 32
      @address  = MoneyTree::Master.new(seed_hex: @hex_seed).to_address
    end
  end
    
  def load_seed_list
    @seeds = File.open(SEED, 'r').split("\n")
    @seed_count = 0
    return @seeds
  end

  def check(address)
    type = @type.to_s
    url  = "https://blockchain.info/q/get#{type}byaddress/#{address}"
    data = Net::HTTP.get URI url
    @balance = data.to_f
    rescue
    puts 'request timeout, repeating process in 60 seconds...'
    sleep(60) and start
  end

  def write_to_file(address, balance, seed, opt = {})
    @data = " #{Time.now.to_s}" + "\n"
    @data += "\n Address: #{address}\n Balance: #{balance}\n HexSeed: #{seed}"
    File.write("#{address}.txt", @data) unless opt[:save] == false
    clr = balance > 0.0 ? :green : :red
    puts @data.colorize(clr)
  end
end

  type = ARGV.include?('--sent') ? :sent : :received

  if ARGV.include?('--start')
    system 'clear'
    puts "\n Starting random seed generation..."
    LuckyBastard.start! 2, type
  else
    puts "\n              Are You Lucky Bastard?".green.bold
    puts "      Generate random hex seed and find out!".green.bold
    print ' '
    50.times { print '='.green } and puts
    puts "  Get received by address:".white
    puts "   $ ruby luckybastard.rb --start".light_green
    puts "  Get sent by address:".white
    puts "   $ ruby luckybastard.rb --start --sent\n".light_green
  end

