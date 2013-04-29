require "fileutils"
require 'pathname'

namespace :assets do
  task :setup => :environment

  desc "Compile all of the assets"
  task :precompile => :environment do
    Rake::Task['assets:precompile:all'].invoke
  end

  namespace :precompile do
    task :all => :environment do
      sprockets = Sprockets.env
      manifest_path = Pathname.new(Share.path_for_application).join('public', 'assets', 'manifest.json')

      manifest = Sprockets.manifest
      manifest.compile
    end
  end

  desc "Remove compiled assets"
  task :clean do
    Rake::Task['assets:clean:all'].invoke
  end

  namespace :clean do
    task :all => :environment do
      public_asset_path = Pathname.new(Share.application_root).join('public', 'assets')
      rm_rf public_asset_path, :secure => true
    end
  end
end
