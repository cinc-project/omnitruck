module OmnitruckDist
  # This class is not fully implemented, depending it is not recommended!
  # Client name
  CLIENT_NAME = "cinc".freeze
  # Here we map specific project versions that started building
  # native SLES packages. This is used to determine which projects
  # need to be remapped to EL before a certain version.
  SLES_PROJECT_VERSIONS = {
    "automate" => "0.8.5",
    "cinc" => "12.21.1",
    "cinc-foundation" => "0.0.0",
    "angrychef" => "12.21.1",
    "cinc-server" => "12.14.0",
    "chefdk" => "1.3.43",
    "cinc-auditor" => "1.20.0",
    "angry-omnibus-toolchain" => "1.1.66",
    "omnibus-toolchain" => "1.1.66",
  }.freeze
end
