require 'fileutils'
require 'tempfile'

module Whenever
  class CommandLine
    def self.execute(options={})
      new(options).run
    end
    
    def initialize(options={})
      @options = options
      
      @options[:file]       ||= 'config/schedule.rb'
      @options[:cut]        ||= 0
      @options[:identifier] ||= default_identifier
      
      unless File.exists?(@options[:file])
        abort("[fail] Can't find file: #{@options[:file]}")
      end

      if [@options[:update], @options[:write], @options[:clear]].compact.length > 1
        abort("[fail] Can only update, write or clear. Choose one.")
      end

      unless @options[:cut].to_s =~ /[0-9]*/
        abort("[fail] Can't cut negative lines from the crontab #{options[:cut]}")
      end
      @options[:cut] = @options[:cut].to_i
    end

    def default_identifier
      File.expand_path(@options[:file])
    end
    
    def run
      writer = Whenever::Api.new(@options)
      if @options[:clear]
        writer.clear_crontab
      elsif @options[:update] 
        writer.update_crontab
      elsif @options[:write]
        writer.write_crontab
      else
        puts Whenever.cron(@options)
        puts "## [message] Above is your schedule file converted to cron syntax; your crontab file was not updated."
        puts "## [message] Run `whenever --help' for more options."
      end
      exit(0)
    rescue => e
      abort(e.message)
    end
  end    
end
