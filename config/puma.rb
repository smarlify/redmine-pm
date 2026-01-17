# Puma configuration for Heroku
# Heroku sets the PORT environment variable
port ENV.fetch("PORT") { 3000 }

# Use threads for better concurrency
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# Worker processes - only use in production (avoid fork issues on macOS in development)
if ENV.fetch("RAILS_ENV") { "development" } == "production"
  # Preload the app for better performance in production
  preload_app!
  
  # Worker processes (Heroku recommends 1-2 workers)
  workers ENV.fetch("WEB_CONCURRENCY") { 2 }
end

# Allow puma to be restarted by `rails restart` command
plugin :tmp_restart

# Logging
if ENV["RAILS_LOG_TO_STDOUT"] && !ENV["RAILS_LOG_TO_STDOUT"].empty?
  stdout_redirect "/dev/stdout", "/dev/stderr", true
end

