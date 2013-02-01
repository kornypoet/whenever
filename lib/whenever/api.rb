require 'fileutils'
require 'tempfile'

module Whenever
  class Api
    
    attr_reader :identifier, :user, :cutlines

    def initialize(options = {})
      @options    = options
      @identifier = options[:identifier]
      @user       = options[:user]
      @cutlines   = options[:cutlines] || 0
    end
    
    def run_cron_command flag
      command  = ['crontab']
      command << "-#{flag}"
      command << "-u #{user}" if user
      [].tap do |results|
        Open3.popen3(*command) do |si, so, se, th|
          results << so.read << se.read << th.value
        end
      end
    end

    def read_crontab
      stdout, stderr, status = run_cron_command(:l)      
      status.exitstatus.zero? ? stdout : ''
    end

    def extract_identifier id
      current_cron = read_crontab
      if current_cron =~ /^#{comment_open}\s*$/ && (current_cron =~ /^#{comment_close}\s*$/).nil?
        raise "[fail] Unclosed indentifier; Your crontab file contains '#{comment_open}', but no '#{comment_close}'"
      elsif (current_cron =~ /^#{comment_open}\s*$/).nil? && read_crontab =~ /^#{comment_close}\s*$/
        raise "[fail] Unopened indentifier; Your crontab file contains '#{comment_close}', but no '#{comment_open}'"
      end
      
    end

    def update_crontab(id, new_contents)
      
    end

    def whenever_cron
      @whenever_cron ||= [comment_open, Whenever.cron(@options), comment_close].compact.join("\n") + "\n"
    end
    
    def read_crontab_old      
      command = ['crontab -l']
      command << "-u #{user}" if user
      
      command_results  = %x[#{command.join(' ')} 2> /dev/null]
      @current_crontab = $?.exitstatus.zero? ? prepare(command_results) : ''
    end
    
    def update_crontab_old
      # Check for unopened or unclosed identifier blocks
      if read_crontab =~ Regexp.new("^#{comment_open}\s*$") && (read_crontab =~ Regexp.new("^#{comment_close}\s*$")).nil?
        raise "[fail] Unclosed indentifier; Your crontab file contains '#{comment_open}', but no '#{comment_close}'"
      elsif (read_crontab =~ Regexp.new("^#{comment_open}\s*$")).nil? && read_crontab =~ Regexp.new("^#{comment_close}\s*$")
        raise "[fail] Unopened indentifier; Your crontab file contains '#{comment_close}', but no '#{comment_open}'"
      end
      
      # If an existing identier block is found, replace it with the new cron entries
      contents = if read_crontab =~ Regexp.new("^#{comment_open}\s*$") && read_crontab =~ Regexp.new("^#{comment_close}\s*$")
        # If the existing crontab file contains backslashes they get lost going through gsub.
        # .gsub('\\', '\\\\\\') preserves them. Go figure.
        read_crontab.gsub(Regexp.new("^#{comment_open}\s*$.+^#{comment_close}\s*$", Regexp::MULTILINE), whenever_cron.chomp.gsub('\\', '\\\\\\'))
      else # Otherwise, append the new cron entries after any existing ones
        [read_crontab, whenever_cron].join("\n\n")
      end.gsub(/\n{3,}/, "\n\n") # More than two newlines becomes just two.      
      write_crontab(contents)
    end
    
    def prepare(contents)
      # Strip n lines from the top of the file as specified by the :cut option.
      # Use split with a -1 limit option to ensure the join is able to rebuild
      # the file with all of the original seperators in-tact.
      stripped_contents = contents.split($/,-1)[cutlines..-1].join($/)

      # Some cron implementations require all non-comment lines to be newline-
      # terminated. (issue #95) Strip all newlines and replace with the default 
      # platform record seperator ($/)
      stripped_contents.gsub!(/\s+$/, $/)      
    end

    def write_crontab(contents = whenever_cron)
      tmp_cron_file = Tempfile.open('whenever_tmp_cron')
      tmp_cron_file << contents
      tmp_cron_file.fsync

      p contents
      
      command  = ['crontab']
      command << "-u #{user}" if user
      command << tmp_cron_file.path
      success  = system(command.join(' '))
      p success, command.join(' ')
      tmp_cron_file.close!
      success
    end
    
    def comment_base
      "Whenever generated tasks for: #{identifier}"
    end
    
    def comment_open
      "# Begin #{comment_base}"
    end
    
    def comment_close
      "# End #{comment_base}"
    end
  end

end
