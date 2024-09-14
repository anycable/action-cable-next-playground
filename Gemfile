source "https://rubygems.org"

rails_path = File.file?(File.join(__dir__, ".rails-path")) ? File.read(File.join(__dir__, ".rails-path")).strip : File.join(__dir__, "../rails")

# Use local Rails copy if available
if ENV["RAILS_VERSION"] == "7"
  gem "rails", "~> 7.0"
elsif File.directory?(rails_path)
  gem "rails", path: rails_path
# Use Rails from a git repo
elsif File.file?(File.join(__dir__, ".rails-revision"))
  git, branch = *File.read(File.join(__dir__, ".rails-revision")).strip.split("#", 2)
  gem "rails", git:, branch:
else
  gem "rails", "~> 8.0"
end

# Baseline setup: Puma + Redis pub/sub
gem "puma", "~> 6.4"
gem "redis", "~> 5.0"

# Async setup
gem "falcon"
gem "async-websocket"
gem "async-redis"

# Iodine
gem "iodine", require: false

# AnyCable setup
gem "grpc_kit" if ENV["ANYCABLE_GRPC_IMPL"] == "grpc_kit"
gem "grpc" unless ENV["ANYCABLE_GRPC_IMPL"] == "grpc_kit"

anycable_dir_path = File.file?(File.join(__dir__, ".anycable-path")) ? File.read(File.join(__dir__, ".anycable-path")).strip : File.join(__dir__, "..")

if ENV["RAILS_VERSION"] == "7"
  gem "anycable-core", require: false
elsif File.file?(File.join(anycable_dir_path, "anycable/anycable-core.gemspec"))
  gem "anycable-core",require: false, path: File.join(anycable_dir_path, "anycable")
elsif File.file?(File.join(__dir__, ".anycable-revision"))
  git, branch = *File.read(File.join(__dir__, ".anycable-revision")).strip.split("#", 2)
  gem "anycable-core", require: false, git:, branch:
else
  gem "anycable-core", require: false
end

if ENV["RAILS_VERSION"] == "7"
  gem "anycable-rails", require: false
elsif File.file?(File.join(anycable_dir_path, "anycable-rails/anycable-rails.gemspec"))
  gem "anycable-rails", require: false, path: File.join(anycable_dir_path, "anycable-rails")
elsif File.file?(File.join(__dir__, ".anycable-rails-revision"))
  git, branch = *File.read(File.join(__dir__, ".anycable-rails-revision")).strip.split("#", 2)
  gem "anycable-rails", require: false, git:, branch:
else
  gem "anycable-rails", require: false
end

# Tools
gem "wsdirector-cli", require: false
gem "anyt", "~> 1.4", require: false

gem "debug" unless ENV["CI"]
