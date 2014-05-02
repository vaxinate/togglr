require 'awesome_print'
require 'thor'
require 'yaml'
require_relative 'togglV8'

class TogglCLI < Thor
  @@config = YAML.load_file("#{File.dirname(__FILE__)}/../config.yml")
  @@toggl = Toggl.new(@@config['toggl_user'], @@config['toggl_pass'])

  desc 'today PROJECT_NAME', 'enter 8 hours on PROJECT_NAME for today'
  def today(project_name)
    if project = find_project(project_name)
      ap @@toggl.create_time_entry(
        description: "development",
        duration: 25200,
        start: today_at_10am.localtime.iso8601,
        pid: project['id'],
        created_with: 'togglr cli!'
      )
    else
      puts "couldn't find project matching #{project_name}"
    end
  end

  desc 'entry PROJECT_NAME NUM_HOURS ENTRY_DATE', 'enter NUM_HOURS hours on PROJECT_NAME for ENTRY_DATE'
  def today(project_name, num_hours, entry_date)
    if project = find_project(project_name)
      ap @@toggl.create_time_entry(
        description: "development",
        duration: num_hours * 3600,
        start: today_at_10am.localtime.iso8601,
        pid: project['id'],
        created_with: 'togglr cli!'
      )
    else
      puts "couldn't find project matching #{project_name}"
    end
  end

  desc 'backfill PROJECT_NAME END_DATE', 'backfill hours on PROJECT_NAME from today to END_DATE (weekends excluded)'
  option :skip
  option :start
  def backfill(project_name, end_date)
    project = find_project(project_name)
    if project.nil?
      puts "couldn't find project matching #{project_name}" and return
    end

    entry_date = options[:start] ? date_at_10am(Date.parse(options[:start])) : today_at_10am 
    end_date = Date.parse(end_date).to_time

    skip_days = options[:skip] ? options[:skip].downcase.split(' ') : []

    while entry_date >= end_date do
      is_weekend = entry_date.saturday? || entry_date.sunday?
      is_skip_day = skip_days.include? entry_date.strftime('%A').downcase

      search_start = Time.new(entry_date.year, entry_date.month, entry_date.day, 0, 0, 0)
      search_end  = Time.new(entry_date.year, entry_date.month, entry_date.day, 24, 0, 0)
      entries = @@toggl.get_time_entries(search_start, search_end)

      if !is_weekend && !is_skip_day && entries.empty?
        ap @@toggl.create_time_entry(
          description: "development",
          duration: 25200,
          start: entry_date.localtime.iso8601,
          pid: project['id'],
          created_with: 'togglr cli!'
        )
      end

      entry_date -= 86400
    end

  end

  no_tasks do
    def find_project(project_name)
    workspace_id = @@toggl.workspaces.first['id']
      @@toggl.projects(workspace_id).find do |p|
        p['name'].match Regexp.new(project_name, true)
      end
    end

    def today_at_10am
      Time.new(Time.now.year, Time.now.month, Time.now.day, 10, 0, 0)
    end

    def date_at_10am(date)
      Time.new(date.year, date.month, date.day, 10, 0, 0)
    end
  end
end
