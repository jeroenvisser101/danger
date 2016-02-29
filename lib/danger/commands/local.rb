module Danger
  class Local < Runner
    self.summary = 'Run the Dangerfile locally.'
    self.command = 'local'

    def initialize(argv)
      @dangerfile_path = "Dangerfile" if File.exist? "Dangerfile"
      super
    end

    def validate!
      super
      unless @dangerfile_path
        help! "Could not find a Dangerfile."
      end
    end

    def run
      ENV["DANGER_USE_LOCAL_GIT"] = "YES"

      dm = Dangerfile.new
      dm.env = EnvironmentManager.new(ENV)

      source = dm.env.ci_source
      unless source.repo_slug
        puts "danger local".red " failed because it only works with GitHub projects at the moment. Sorry."
        exit 0
      end

      puts "Running your Dangerfile against this PR - https://github.com/#{source.repo_slug}/pulls/#{source.pull_request_id}"

      if verbose != true
        puts "Turning on --verbose"
        dm.verbose = true
      end

      puts ""

      gh = GitHub.new(dm.env.ci_source, ENV)
      # We can use tokenless here, as it's running on someone's computer
      # and is IP locked, as opposed  to on the CI.
      gh.support_tokenless_auth = true
      gh.fetch_details

      dm.env.request_source = gh

      dm.env.scm = GitRepo.new

      dm.env.scm.diff_for_folder(".", from: dm.env.ci_source.base_commit, to: dm.env.ci_source.head_commit)
      dm.parse Pathname.new(@dangerfile_path)
    end
  end
end
