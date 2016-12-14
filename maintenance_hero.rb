#!/usr/bin/env ruby
# frozen_string_literal: true

require 'platform-api'
require 'json'
require 'optparse'
require 'pry'

options = {}

module MaintenanceHero
  class Scaler
    def initialize(token:, dir:, opts: options)
      @api = PlatformAPI.connect_oauth(opts[:oauth_token])
      @app = opts[:app]
      @dir = dir
      @scale_down_web = !dir
      @options = opts
    end

    def scale_up(file, formation)
    end

    def scale_down(formation, leave_web:false)
      dyno_updates = []

      formations.each do |f|
        next if leave_web && f['type'] == "web"
        dyno_updates << {
          process: f['type'],
          quantity: 0,
          size: f['size']
        }
      end

      apply_formation_updates(dyno_updates)
    end

    private

    def apply_formation_updates(updates)
      @api.formation.batch_update(@app, updates: updates)
    end

    def get_formation
      @api.formation.list(@app)
    end

    def save_formation(file, formation)
      File.open(file, 'w') do |f|
        f.write(formation_minimal(formation).to_json)
      end
    end

    def read_formation(file)
      JSON.parse(File.read(file))
    end

    def formation_minimal(formation)
      min_formation = []
      formation.each do |f|
        min_formation << {
          process: f['type'],
          quantity: f['quantity'],
          size: f['size']
        }
      end
      min_formation
    end

    # Convert private dyno types to common runtime dyno types
    # I.e. Private-S to Standard-1X
    def private_to_common(formation)
      formation.each do |f|
        f['size'] = dyno_map.invert[f['size']]
      end
    end

    # Convert common runtime dyno types to private dyno types
    # I.e. Standard-2X to Private-M
    def common_to_private(formation)
      formation.each do |f|
        f['size'] = dyno_map[f['size']]
      end
    end

    # Mapping from common runtime to private space dynos
    def dyno_map
      {
        "Standard-1X": "Private-S",
        "Standard-2X": "Private-S",
        "Performance-M": "Private-M",
        "Performance-L": "Private-L",
      }
    end
  end
end

### Main
option_parser = OptionParser.new do |parser|
  parser.banner = "Usage: maintenance_hero.rb [options]"

  parser.on("-h", "--help", "Show this help message") do ||
    puts parser
  end

  parser.on("-a", "--app APP", "Specify app name") do |app|
    puts "app: #{app}"
    options[:app] = app
  end

  parser.on("-s", "--scale [DIR]", [:up, :down], "Scale dynos (up, down)") do |dir|
    puts "Scaling dynos #{dir}!"
    options[:dir] = dir
  end
end

begin
  option_parser.parse!(ARGV)
rescue OptionParser::MissingArgument => e
  $stderr.print "Error - " + e.message + "\n"
  exit
end

puts "options: #{options}"
#mh = MaintenanceHero::Scaler.new(token:"blah", dir:dir, opts: options)

#save_formation("formation-#{Time.now.to_i}.json", formations)

# Scale Down Dynos
#heroku.formation.batch_update(TARGET_APP, updates: dyno_updates)

#heroku.formation.batch_update(TARGET_APP, updates: scale_up)
