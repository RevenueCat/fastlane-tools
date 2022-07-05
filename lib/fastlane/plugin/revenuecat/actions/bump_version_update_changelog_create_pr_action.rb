require 'fastlane/action'
require 'fastlane_core/configuration/config_item'
require_relative '../helper/revenuecat_helper'

module Fastlane
  module Actions
    class BumpVersionUpdateChangelogCreatePRAction < Action
      def self.run(params)
        branch = params[:branch]
        repo_name = params[:repo_name]
        github_token = params[:github_token]
        rate_limit_sleep = params[:github_rate_limit]
        verbose = params[:verbose]
        version_number = params[:current_version]
        files_to_update = params[:files_to_update]
        files_to_update_without_prerelease_modifiers = params[:files_to_update_without_prerelease_modifiers]

        ensure_git_branch(branch: branch)
        ensure_git_status_clean

        # Ensure GitHub API token is set
        github_pr_token = ENV.fetch(:github_pr_token, nil)
        if github_pr_token.nil? || github_pr_token.empty?
          UI.error("Environment variable GITHUB_PULL_REQUEST_API_TOKEN is required to create a pull request")
          UI.error("Please make a fastlane/.env file from the fastlane/.env.SAMPLE template")
          UI.user_error!("Could not find value for GITHUB_PULL_REQUEST_API_TOKEN")
        end

        UI.important("Current version is #{version_number}")

        # Ask for new version number
        new_version_number = UI.input("New version number: ")

        generated_contents = Helper::RevenuecatHelper.auto_generate_changelog(repo_name, version_number, github_token, rate_limit_sleep, verbose)
        changelog_latest_path = File.absolute_path("../CHANGELOG.latest.md")
        changelog_path = File.absolute_path("../CHANGELOG.md")
        Helper::RevenuecatHelper.edit_changelog(generated_contents, changelog_path, editor)
        changelog = File.read(changelog_path)

        Helper::RevenuecatHelper.create_new_release_branch(new_version_number)
        Helper::RevenuecatHelper.replace_version_number(version_number,
                                                        new_version_number,
                                                        files_to_update,
                                                        files_to_update_without_prerelease_modifiers)
        Helper::RevenuecatHelper.attach_changelog_to_master(new_version_number, changelog_latest_path, changelog_path)
        Helper::RevenuecatHelper.commmit_changes_and_push_current_branch("Version bump for #{new_version_number}")

        create_pull_request(
          title: "Release/#{new_version_number}",
          base: "main",
          body: changelog
        )
      end

      def self.description
        "Bumps sdk version, asks to update changelog and creates PR with changes."
      end

      def self.authors
        ["Toni Rico"]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :current_version,
                                       description: "Current version of the sdk",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :files_to_update,
                                       env_name: "FILES_TO_UPDATE_VERSION",
                                       description: "Files that contain the version number and need to have it updated",
                                       optional: false,
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :files_to_update_without_prerelease_modifiers,
                                       env_name: "FILES_TO_UPDATE_VERSION_WITHOUT_PRERELEASE_MODIFIERS",
                                       description: "Files that contain the version number without release modifiers and need to have it updated",
                                       optional: true,
                                       default_value: [],
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :repo_name,
                                       env_name: "REPO_NAME",
                                       description: "Name of the repo of the SDK",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :github_token,
                                       env_name: "GITHUB_TOKEN",
                                       description: "Github token to use to prepopulate the changelog",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :github_rate_limit,
                                       env_name: "GITHUB_RATE_LIMIT_SLEEP",
                                       description: "Sets a rate limiter for github requests when creating the changelog",
                                       optional: true,
                                       default_value: 0,
                                       type: Integer),
          FastlaneCore::ConfigItem.new(key: :branch,
                                       description: "Allows to execute the action from the given branch",
                                       optional: true,
                                       default_value: "main",
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :editor,
                                       env_name: "FASTLANE_EDITOR",
                                       description: "Allows to override editor to be used when editting the changelog",
                                       optional: true,
                                       default_value: "vim",
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :verbose,
                                       description: "Sets whether to print extra information",
                                       optional: true,
                                       default_value: false,
                                       is_string: false)
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
