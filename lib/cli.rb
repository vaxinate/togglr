require 'awesome_print'
require 'thor'
require_relative 'togglV8'

class TogglCLI < Thor
  @@toggl = Toggl.new('adam@revelry.co', 'b0bd0Le!')

  desc 'today PROJECT_NAME', 'enter 8 hours on PROJECT_NAME for today'
  def today(project_name)
    if project = find_project(project_name)
      puts @@toggl.create_time_entry(
        description: "development",
        duration: 25200,
        start: today_at_10_am,
        pid: project['id'],
        created_with: 'togglr cli!'
      )
    else
      puts "couldn't find project matching #{project_name}"
    end
  end

  desc 'backfill PROJECT_NAME END_DATE', 'backfill hours on PROJECT_NAME from today to END_DATE'
  def backfill(project_name, end_date)
    project = find_project(project_name)
    if project.nil?
      puts "couldn't find project matching #{project_name}" and return
    end

    entry_date = today_at_10am
    end_date = Date.parse(end_date).to_time

    while entry_date >= end_date do
      is_weekend = entry_date.saturday? || entry_date.sunday?

      search_start = Time.new(entry_date.year, entry_date.month, entry_date.day, 0, 0, 0)
      search_end  = Time.new(entry_date.year, entry_date.month, entry_date.day, 24, 0, 0)
      entries = @@toggl.get_time_entries(search_start, search_end)

      if !is_weekend && entries.empty?
        puts @@toggl.create_time_entry(
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
  end
end