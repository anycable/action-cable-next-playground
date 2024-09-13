source "https://rubygems.org"

rails_path = File.file?(File.join(__dir__, ".rails-path")) ? File.read(File.join(__dir__, ".rails-path")).strip : File.join(__dir__, "../rails")

# Use local Rails copy if available
if File.directory?(rails_path)
  gem "rails", group: :preload, path: rails_path
# Use Rails from a git repo
elsif File.file?(File.join(__dir__, ".rails-revision"))
  git, branch = *File.read(File.join(__dir__, ".rails-revision")).strip.split("#", 2)
  gem "rails", group: :preload, git:, branch:
else
  gem "rails", "~> 8.0"
end

# Baseline setup: Puma + Redis pub/sub
gem "puma", "~> 6.4"
gem "redis", "~> 5.0", group: :preload

# Async setup
# TODO

# AnyCable setup
gem "grpc_kit" if ENV["ANYCABLE_GRPC_IMPL"] == "grpc_kit"
gem "grpc" unless ENV["ANYCABLE_GRPC_IMPL"] == "grpc_kit"

anycable_dir_path = File.file?(File.join(__dir__, ".anycable-path")) ? File.read(File.join(__dir__, ".anycable-path")).strip : File.join(__dir__, "..")

if File.file?(File.join(anycable_dir_path, "anycable/anycable-core.gemspec"))
  gem "anycable-core", group: :preload, path: File.join(anycable_dir_path, "anycable")
elsif File.file?(File.join(__dir__, ".anycable-revision"))
  git, branch = *File.read(File.join(__dir__, ".anycable-revision")).strip.split("#", 2)
  gem "anycable-core", require: false, group: :preload, git:, branch:
else
  gem "anycable-core"
end

if File.file?(File.join(anycable_dir_path, "anycable-rails/anycable-rails.gemspec"))
  gem "anycable-rails", group: :preload, path: File.join(anycable_dir_path, "anycable-rails")
elsif File.file?(File.join(__dir__, ".anycable-rails-revision"))
  git, branch = *File.read(File.join(__dir__, ".anycable-rails-revision")).strip.split("#", 2)
  gem "anycable-rails", require: false, group: :preload, git:, branch:
else
  gem "anycable-rails"
end

# Tools
gem "wsdirector-cli", require: false
gem "anyt", "~> 1.4", require: false

gem "debug" unless ENV["CI"]
