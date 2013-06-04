task :environment do
  require "./config/environment"
end

namespace :db do
  desc "populate db with default data"
  task :seed => :environment do
    seed_path = File.join(Webmate.root, 'db', 'seed.rb')
    if FileTest.exists?(seed_path)
      require(seed_path)
    else
      puts "Seed file not found (searched at #{ seed_path.inspect })"
    end
  end
end

desc "show all routes"
task :routes => :environment do
  show_routes(Webmate::Application.routes.routes)
end

desc "example task" do
  task 'example' do
    puts 'its working'
  end
end

def show_routes(routes)
  routes.each do |method, method_routes|
    puts '-' * 80
    method_routes.each do |transport, routes|
      routes.each {|route| show_route(transport, route)}
    end
  end
end

def show_route(transport, route)
  puts [
    transport.to_s.upcase.rjust(4),
    route.method.to_s.upcase.rjust(6),
    route.path.to_s.ljust(50),
    "=> #{route.responder.to_s}##{route.action}"
  ].join(' ')
end
