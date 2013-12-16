require 'rake'
require 'rake/tasklib'

module Whenever

  def self.default_tasks
    InstallTask.new
    UninstallTask.new
  end

  class RakeTask < ::Rake::TaskLib
    include ::Rake::DSL if defined?(::Rake::DSL)

    attr_accessor :name, :verbose, :fail_on_error

    def initialize(*args, &task_block)
      @name = args.shift || default_taskname
      @verbose, @fail_on_error = true, true
      @failure_message = nil

      desc(task_description)

      task name, *args do |t, task_args|
        task_block.call(*[self, task_args].slice(0, task_block.arity)) if task_block
        begin
          # do something verbose if verbose
          success = system(command)
        rescue => e
          puts failure_message if failure_message
        end
        raise 'Whenever task failed' if fail_on_error unless success        
      end
    end    
  end
  
  class InstallTask < RakeTask

    def default_taskname
      'whenever:install'
    end
    
    def task_description
      'Use Whenever to install cron jobs'
    end

    def command
      
    end

  end

  class UninstallTask < RakeTask


    def default_taskname
      'whenever:uninstall'
    end

    def task_description
      'Use Whenever to uninstall cron jobs'
    end

    def command
      
    end

  end
end
