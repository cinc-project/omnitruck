require 'sinatra'
require 'sinatra/config_file'
require 'json'

class Omnitruck < Sinatra::Base
  register Sinatra::ConfigFile

  config_file './config/config.yml'

  class InvalidPlatform < StandardError; end
  class InvalidPlatformVersion < StandardError; end
  class InvalidMachine < StandardError; end
  class InvalidChefVersion < StandardError; end

  set :raise_errors, Proc.new { false }
  set :show_exceptions, false

  RACK_ENV = "development"

  #
  # serve up the installer script
  #
  get '/install.sh' do
    content_type :sh
    erb :'install.sh', { :layout => :'install.sh', :locals => { :base_url => settings.base_url } }
  end

  error InvalidDownloadPath do
    status 404
    err = env['sinatra.error'].message.split(":")
    "No chef-client #{err[0]} installer for #{err[1]}-#{err[2]}-#{err[3]}"
  end

  #
  # download an omnibus chef package
  #
  # == Params
  #
  # * :version:          - The version of Chef to download
  # * :platform:         - The platform to install on
  # * :platform_version: - The platfrom version to install on
  # * :machine:          - The machine architecture to install on
  #
  get '/download' do
    chef_version     = params['v']
    platform         = params['p']
    platform_version = params['pv']
    machine          = params['m']

    f = File.read(settings.build_list)
    directory = JSON.parse(f)
    platform_dir = directory[platform]
    error = "#{chef_version}:#{platform}:#{platform_version}:#{machine}"
    raise InvalidDownloadPath, error if platform_dir.nil?
    plat_version_dir = platform_dir[platform_version]
    raise InvalidDownloadPath, error if plat_version_dir.nil?
    machine_dir = plat_version_dir[machine]
    raise InvalidDownloadPath, error if machine_dir.nil?
    if chef_version.nil?
      chef_version = latest_version(machine_dir.keys)
    elsif !chef_version.include?("-")
      chef_version = latest_iteration(machine_dir.keys, chef_version)
    end
    url = machine_dir[chef_version]
    raise InvalidDownloadPath, error if url.nil?
    redirect url
  end

  # Returns the latest chef version from a list
  def latest_version(versions)
    latest = '0.0.0'
    versions.each do |v|
      latest = which_bigger(v, latest)
    end
    latest
  end

  # Returns the most recent chef version of the two passed in
  # Requires version of the form /\d+\.\d+\.\d+-?\d?+/
  #                          eg. 0.10.8, 10.12.0-1

  def which_bigger(a, b)
    a_iter = 0
    b_iter = 0
    result = nil
    if a.include?("-")
      a_iter = (a.split("-")[1])
      a = a.split("-")[0]
    end
    if b.include?("-")
      b_iter = (b.split("-")[1])
      b = b.split("-")[0]
    end
    a_parts = a.split(".")
    b_parts = b.split(".")
    (0..2).each do |i|
      Integer(a_parts[i]) > Integer(b_parts[i]) ? (result = "#{a}-#{a_iter}") : (result = "#{b}-#{b_iter}") unless a_parts[i] == b_parts[i]
      break if !result.nil?
    end
    # if execution gets here, aa.aa.aa = bb.bb.bb, go to iteration
    Integer(a_iter) > Integer(b_iter) ? (result = "#{a}-#{a_iter}") : (result = "#{b}-#{b_iter}") if result.nil?
    if result[-1] == '0'
      result = result.split("-")[0]
    end
    result
  end

  # grabs the latest iteration of a given version of chef
  def latest_iteration(versions, chef_version)
    c_v = chef_version
    versions.each do |v|
      if v.include?(chef_version)
        if v.include?("-")
          if c_v.include?("-")
            Integer(v.split("-")[1]) > Integer(c_v.split("-")[1]) ? (c_v = v) : (c_v)
          else
            c_v = v
          end
        end
      end
    end
    c_v
  end
end
