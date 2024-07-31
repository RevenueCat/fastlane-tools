describe Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction do
  describe '#run' do
    let(:mock_github_pr_token) { 'mock-github-pr-token' }
    let(:mock_github_token) { 'mock-github-token' }
    let(:mock_repo_name) { 'mock-repo-name' }
    let(:mock_changelog_latest_path) { './fake-changelog-latest-path/CHANGELOG.latest.md' }
    let(:mock_changelog_path) { './fake-changelog-path/CHANGELOG.md' }
    let(:editor) { 'vim' }
    let(:auto_generated_changelog) { 'mock-auto-generated-changelog' }
    let(:edited_changelog) { 'mock-edited-changelog' }
    let(:current_version) { '1.12.0' }
    let(:base_branch) { 'main' }
    let(:new_version) { '1.13.0' }
    let(:new_branch_name) { 'release/1.13.0' }
    let(:labels) { ['next_release'] }
    let(:hybrid_common_version) { '4.5.3' }
    let(:versions_file_path) { '../VERSIONS.md' }

    it 'fails if version is invalid' do
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(true)
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return('')

      expect(FastlaneCore::UI).to receive(:user_error!)
        .with('Version number cannot be empty')
        .once
        .and_throw(:expected_error)

      catch :expected_error do
        Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
          current_version: current_version,
          changelog_latest_path: mock_changelog_latest_path,
          changelog_path: mock_changelog_path,
          repo_name: mock_repo_name,
          github_pr_token: mock_github_pr_token,
          github_token: mock_github_token,
          editor: editor
        )
      end
    end

    it 'calls all the appropriate methods with appropriate parameters' do
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(true)
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return(new_version)
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)
      allow(File).to receive(:read).with(mock_changelog_latest_path).and_return(edited_changelog)
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:validate_local_config_status_for_bump)
        .with('release/1.13.0', mock_github_pr_token)
        .once
      expect(Fastlane::Helper::VersioningHelper).to receive(:auto_generate_changelog)
        .with(mock_repo_name, mock_github_token, 3, false, nil, nil)
        .and_return(auto_generated_changelog)
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:edit_changelog)
        .with(auto_generated_changelog, mock_changelog_latest_path, editor)
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:create_new_branch_and_checkout)
        .with(new_branch_name)
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:replace_version_number)
        .with(current_version,
              new_version,
              { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
              { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
              { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] })
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:attach_changelog_to_master)
        .with(new_version, mock_changelog_latest_path, mock_changelog_path)
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:commit_changes_and_push_current_branch)
        .with("Version bump for #{new_version}")
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:create_pr)
        .with("Release/1.13.0", edited_changelog, mock_repo_name, base_branch, new_branch_name, mock_github_pr_token, labels)
        .once

      Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
        current_version: current_version,
        changelog_latest_path: mock_changelog_latest_path,
        changelog_path: mock_changelog_path,
        files_to_update: { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
        files_to_update_without_prerelease_modifiers: { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
        files_to_update_on_latest_stable_releases: { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] },
        repo_name: mock_repo_name,
        github_pr_token: mock_github_pr_token,
        github_token: mock_github_token,
        github_rate_limit: 3,
        editor: editor,
        is_prerelease: false
      )
    end

    it 'generates changelog with appropriate parameters when bumping a hybrid SDK' do
      setup_stubs
      expect(Fastlane::Helper::VersioningHelper).to receive(:auto_generate_changelog)
        .with(mock_repo_name, mock_github_token, 3, false, hybrid_common_version, versions_file_path)
        .and_return(auto_generated_changelog)
        .once

      Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
        current_version: current_version,
        changelog_latest_path: mock_changelog_latest_path,
        changelog_path: mock_changelog_path,
        files_to_update: { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
        files_to_update_without_prerelease_modifiers: { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
        files_to_update_on_latest_stable_releases: { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] },
        repo_name: mock_repo_name,
        github_pr_token: mock_github_pr_token,
        github_token: mock_github_token,
        github_rate_limit: 3,
        editor: editor,
        hybrid_common_version: hybrid_common_version,
        versions_file_path: versions_file_path,
        is_prerelease: false
      )
    end

    it 'fails if selected no during prompt validating current branch' do
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(true)
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(false)
      expect do
        Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
          current_version: current_version,
          changelog_latest_path: mock_changelog_latest_path,
          changelog_path: mock_changelog_path,
          files_to_update: { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
          files_to_update_without_prerelease_modifiers: { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
          files_to_update_on_latest_stable_releases: { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] },
          repo_name: mock_repo_name,
          github_pr_token: mock_github_pr_token,
          github_token: mock_github_token,
          github_rate_limit: 3,
          editor: editor,
          is_prerelease: false
        )
      end.to raise_exception(StandardError)
    end

    it 'does not prompt for branch confirmation if UI is not interactive' do
      setup_stubs

      Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
        current_version: current_version,
        changelog_latest_path: mock_changelog_latest_path,
        changelog_path: mock_changelog_path,
        files_to_update: { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
        files_to_update_without_prerelease_modifiers: { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
        files_to_update_on_latest_stable_releases: { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] },
        repo_name: mock_repo_name,
        github_pr_token: mock_github_pr_token,
        github_token: mock_github_token,
        github_rate_limit: 3,
        editor: editor,
        is_prerelease: false
      )
    end

    it 'does not edit changelog if UI is not interactive' do
      setup_stubs

      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:write_changelog)
        .with(auto_generated_changelog, mock_changelog_latest_path)
      expect(Fastlane::Helper::RevenuecatInternalHelper).to_not(receive(:edit_changelog)
                                                                  .with(auto_generated_changelog, mock_changelog_latest_path, editor))
      Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
        current_version: current_version,
        changelog_latest_path: mock_changelog_latest_path,
        changelog_path: mock_changelog_path,
        files_to_update: { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
        files_to_update_without_prerelease_modifiers: { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
        files_to_update_on_latest_stable_releases: { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] },
        repo_name: mock_repo_name,
        github_pr_token: mock_github_pr_token,
        github_token: mock_github_token,
        github_rate_limit: 3,
        editor: editor,
        is_prerelease: false
      )
    end

    it 'adds automatic label to title and body' do
      setup_stubs

      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:create_pr)
        .with("[AUTOMATIC] Release/1.13.0", "**This is an automatic release.**\n\nmock-edited-changelog", mock_repo_name, base_branch, new_branch_name, mock_github_pr_token, labels)

      Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
        current_version: current_version,
        changelog_latest_path: mock_changelog_latest_path,
        changelog_path: mock_changelog_path,
        files_to_update: { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
        files_to_update_without_prerelease_modifiers: { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
        files_to_update_on_latest_stable_releases: { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] },
        repo_name: mock_repo_name,
        github_pr_token: mock_github_pr_token,
        github_token: mock_github_token,
        github_rate_limit: 3,
        editor: editor,
        automatic_release: true,
        is_prerelease: false
      )
    end

    it 'fails trying to append PHC version if is_prerelease is true' do
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(true)
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return(new_version)
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)
      allow(File).to receive(:read).with(mock_changelog_latest_path).and_return(edited_changelog)

      expect(FastlaneCore::UI).to receive(:user_error!)
        .with('Appending the PHC version to prerelease versions violates SemVer.')
        .once
        .and_throw(:expected_error)

      catch :expected_error do
        Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
          current_version: current_version,
          changelog_latest_path: mock_changelog_latest_path,
          changelog_path: mock_changelog_path,
          repo_name: mock_repo_name,
          github_pr_token: mock_github_pr_token,
          github_token: mock_github_token,
          editor: editor,
          hybrid_common_version: hybrid_common_version,
          is_prerelease: true,
          append_hybrid_common_version: true
        )
      end
    end

    it 'fails trying to append PHC version if new version is prerelease' do
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(true)
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return('1.13.0-alpha.1')
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)
      allow(File).to receive(:read).with(mock_changelog_latest_path).and_return(edited_changelog)

      expect(FastlaneCore::UI).to receive(:user_error!)
        .with('Appending the PHC version to prerelease versions violates SemVer.')
        .once
        .and_throw(:expected_error)

      catch :expected_error do
        Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
          current_version: current_version,
          changelog_latest_path: mock_changelog_latest_path,
          changelog_path: mock_changelog_path,
          repo_name: mock_repo_name,
          github_pr_token: mock_github_pr_token,
          github_token: mock_github_token,
          editor: editor,
          hybrid_common_version: hybrid_common_version,
          is_prerelease: false,
          append_hybrid_common_version: true
        )
      end
    end

    it 'fails trying to append a nil PHC version' do
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(true)
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return(new_version)
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)
      allow(File).to receive(:read).with(mock_changelog_latest_path).and_return(edited_changelog)

      expect(FastlaneCore::UI).to receive(:user_error!)
        .with('Cannot append a nil PHC version.')
        .once
        .and_throw(:expected_error)

      catch :expected_error do
        Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
          current_version: current_version,
          changelog_latest_path: mock_changelog_latest_path,
          changelog_path: mock_changelog_path,
          repo_name: mock_repo_name,
          github_pr_token: mock_github_pr_token,
          github_token: mock_github_token,
          editor: editor,
          hybrid_common_version: nil,
          is_prerelease: false,
          append_hybrid_common_version: true
        )
      end
    end

    it 'appends the PHC version automatically if append_hybrid_common_version is true and provided version lacks metadata - interactive' do
      # Arrange
      interactive = true
      append_hybrid_common_version = true
      new_version_appended = "#{new_version}+#{hybrid_common_version}"
      new_branch_name = "release/#{new_version_appended}"
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(interactive)
      # We are providing new_version, without PHC appended as metadata
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return(new_version)
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)
      allow(File).to receive(:read).with(mock_changelog_latest_path).and_return(edited_changelog)
      allow(Fastlane::Helper::VersioningHelper).to receive(:auto_generate_changelog)
        .with(mock_repo_name, mock_github_token, 3, false, hybrid_common_version, nil)
        .and_return(auto_generated_changelog)
        .once
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:edit_changelog)
        .with(auto_generated_changelog, mock_changelog_latest_path, editor)
        .once

      # Assert
      expect(FastlaneCore::UI).not_to receive(:confirm)
        .with("Would you like to append the PHC version (+#{hybrid_common_version})?")

      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:validate_local_config_status_for_bump)
        .with(new_branch_name, mock_github_pr_token)
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:replace_version_number)
        .with(current_version,
              new_version_appended,
              { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
              { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
              { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] })
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:attach_changelog_to_master)
        .with(new_version_appended, mock_changelog_latest_path, mock_changelog_path)
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:create_pr)
        .with("Release/#{new_version_appended}", edited_changelog, mock_repo_name, base_branch, new_branch_name, mock_github_pr_token, labels)
        .once

      # Act
      Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
        current_version: current_version,
        changelog_latest_path: mock_changelog_latest_path,
        changelog_path: mock_changelog_path,
        files_to_update: { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
        files_to_update_without_prerelease_modifiers: { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
        files_to_update_on_latest_stable_releases: { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] },
        repo_name: mock_repo_name,
        github_pr_token: mock_github_pr_token,
        github_token: mock_github_token,
        github_rate_limit: 3,
        editor: editor,
        hybrid_common_version: hybrid_common_version,
        is_prerelease: false,
        append_hybrid_common_version: append_hybrid_common_version
      )
    end

    it 'succeeds if append_hybrid_common_version is true and provided version metadata matches - interactive' do
      # Arrange
      interactive = true
      append_hybrid_common_version = true
      new_version_appended = "#{new_version}+#{hybrid_common_version}"
      new_branch_name = "release/#{new_version_appended}"
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(interactive)
      # We are providing new_version_appended, with the correct PHC version already appended as metadata
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return(new_version_appended)
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)
      allow(File).to receive(:read).with(mock_changelog_latest_path).and_return(edited_changelog)
      allow(Fastlane::Helper::VersioningHelper).to receive(:auto_generate_changelog)
        .with(mock_repo_name, mock_github_token, 3, false, hybrid_common_version, nil)
        .and_return(auto_generated_changelog)
        .once
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:edit_changelog)
        .with(auto_generated_changelog, mock_changelog_latest_path, editor)
        .once

      # Assert
      expect(FastlaneCore::UI).not_to receive(:confirm)
        .with("Would you like to append the PHC version (+#{hybrid_common_version})?")

      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:validate_local_config_status_for_bump)
        .with(new_branch_name, mock_github_pr_token)
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:replace_version_number)
        .with(current_version,
              new_version_appended,
              { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
              { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
              { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] })
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:attach_changelog_to_master)
        .with(new_version_appended, mock_changelog_latest_path, mock_changelog_path)
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:create_pr)
        .with("Release/#{new_version_appended}", edited_changelog, mock_repo_name, base_branch, new_branch_name, mock_github_pr_token, labels)
        .once

      # Act
      Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
        current_version: current_version,
        changelog_latest_path: mock_changelog_latest_path,
        changelog_path: mock_changelog_path,
        files_to_update: { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
        files_to_update_without_prerelease_modifiers: { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
        files_to_update_on_latest_stable_releases: { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] },
        repo_name: mock_repo_name,
        github_pr_token: mock_github_pr_token,
        github_token: mock_github_token,
        github_rate_limit: 3,
        editor: editor,
        hybrid_common_version: hybrid_common_version,
        is_prerelease: false,
        append_hybrid_common_version: append_hybrid_common_version
      )
    end

    it 'fails if append_hybrid_common_version is true and provided version metadata does not match - interactive' do
      # Arrange
      interactive = true
      append_hybrid_common_version = true
      mismatched_metadata = "some.metadata"
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(interactive)
      # We are providing a version with metadata that doesn't match the PHC version
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return("#{new_version}+#{mismatched_metadata}")
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)

      # Assert
      expect(FastlaneCore::UI).not_to receive(:confirm)
        .with("Would you like to append the PHC version (+#{hybrid_common_version})?")

      expect(FastlaneCore::UI).to receive(:user_error!)
        .with("Asked to append PHC version (+#{hybrid_common_version}), but the version provided already has metadata (+#{mismatched_metadata}).")
        .once
        .and_throw(:expected_error)

      # Act
      catch :expected_error do
        Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
          current_version: current_version,
          changelog_latest_path: mock_changelog_latest_path,
          changelog_path: mock_changelog_path,
          repo_name: mock_repo_name,
          github_pr_token: mock_github_pr_token,
          github_token: mock_github_token,
          github_rate_limit: 3,
          editor: editor,
          hybrid_common_version: hybrid_common_version,
          is_prerelease: false,
          append_hybrid_common_version: append_hybrid_common_version
        )
      end
    end

    it 'fails if append_hybrid_common_version is true and provided version has + but no metadata - interactive' do
      # Arrange
      interactive = true
      append_hybrid_common_version = true
      mismatched_metadata = "" # Empty on purpose
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(interactive)
      # We are providing a version with metadata that doesn't match the PHC version
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return("#{new_version}+#{mismatched_metadata}")
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)

      # Assert
      expect(FastlaneCore::UI).not_to receive(:confirm)
        .with("Would you like to append the PHC version (+#{hybrid_common_version})?")

      expect(FastlaneCore::UI).to receive(:user_error!)
        .with("Asked to append PHC version (+#{hybrid_common_version}), but the version provided already has metadata (+#{mismatched_metadata}).")
        .once
        .and_throw(:expected_error)

      # Act
      catch :expected_error do
        Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
          current_version: current_version,
          changelog_latest_path: mock_changelog_latest_path,
          changelog_path: mock_changelog_path,
          repo_name: mock_repo_name,
          github_pr_token: mock_github_pr_token,
          github_token: mock_github_token,
          github_rate_limit: 3,
          editor: editor,
          hybrid_common_version: hybrid_common_version,
          is_prerelease: false,
          append_hybrid_common_version: append_hybrid_common_version
        )
      end
    end

    it 'appends the PHC version automatically if append_hybrid_common_version is true and provided version lacks metadata - non-interactive' do
      # Arrange
      interactive = false
      append_hybrid_common_version = true
      new_version_appended = "#{new_version}+#{hybrid_common_version}"
      new_branch_name = "release/#{new_version_appended}"
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(interactive)
      # We are providing new_version, without PHC appended as metadata
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return(new_version)
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)
      allow(File).to receive(:read).with(mock_changelog_latest_path).and_return(edited_changelog)
      allow(Fastlane::Helper::VersioningHelper).to receive(:auto_generate_changelog)
        .with(mock_repo_name, mock_github_token, 3, false, hybrid_common_version, nil)
        .and_return(auto_generated_changelog)
        .once
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:write_changelog)
        .with(auto_generated_changelog, mock_changelog_latest_path)
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:edit_changelog)
        .with(auto_generated_changelog, mock_changelog_latest_path, editor)
        .once

      # Assert
      expect(FastlaneCore::UI).not_to receive(:confirm)
        .with("Would you like to append the PHC version (+#{hybrid_common_version})?")

      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:validate_local_config_status_for_bump)
        .with(new_branch_name, mock_github_pr_token)
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:replace_version_number)
        .with(current_version,
              new_version_appended,
              { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
              { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
              { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] })
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:attach_changelog_to_master)
        .with(new_version_appended, mock_changelog_latest_path, mock_changelog_path)
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:create_pr)
        .with("Release/#{new_version_appended}", edited_changelog, mock_repo_name, base_branch, new_branch_name, mock_github_pr_token, labels)
        .once

      # Act
      Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
        current_version: current_version,
        changelog_latest_path: mock_changelog_latest_path,
        changelog_path: mock_changelog_path,
        files_to_update: { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
        files_to_update_without_prerelease_modifiers: { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
        files_to_update_on_latest_stable_releases: { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] },
        repo_name: mock_repo_name,
        github_pr_token: mock_github_pr_token,
        github_token: mock_github_token,
        github_rate_limit: 3,
        editor: editor,
        hybrid_common_version: hybrid_common_version,
        is_prerelease: false,
        append_hybrid_common_version: append_hybrid_common_version
      )
    end

    it 'succeeds if append_hybrid_common_version is true and provided version metadata matches - non-interactive' do
      # Arrange
      interactive = false
      append_hybrid_common_version = true
      new_version_appended = "#{new_version}+#{hybrid_common_version}"
      new_branch_name = "release/#{new_version_appended}"
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(interactive)
      # We are providing new_version_appended, with the correct PHC version already appended as metadata
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return(new_version_appended)
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)
      allow(File).to receive(:read).with(mock_changelog_latest_path).and_return(edited_changelog)
      allow(Fastlane::Helper::VersioningHelper).to receive(:auto_generate_changelog)
        .with(mock_repo_name, mock_github_token, 3, false, hybrid_common_version, nil)
        .and_return(auto_generated_changelog)
        .once
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:write_changelog)
        .with(auto_generated_changelog, mock_changelog_latest_path)
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:edit_changelog)
        .with(auto_generated_changelog, mock_changelog_latest_path, editor)
        .once

      # Assert
      expect(FastlaneCore::UI).not_to receive(:confirm)
        .with("Would you like to append the PHC version (+#{hybrid_common_version})?")

      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:validate_local_config_status_for_bump)
        .with(new_branch_name, mock_github_pr_token)
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:replace_version_number)
        .with(current_version,
              new_version_appended,
              { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
              { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
              { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] })
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:attach_changelog_to_master)
        .with(new_version_appended, mock_changelog_latest_path, mock_changelog_path)
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:create_pr)
        .with("Release/#{new_version_appended}", edited_changelog, mock_repo_name, base_branch, new_branch_name, mock_github_pr_token, labels)
        .once

      # Act
      Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
        current_version: current_version,
        changelog_latest_path: mock_changelog_latest_path,
        changelog_path: mock_changelog_path,
        files_to_update: { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
        files_to_update_without_prerelease_modifiers: { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
        files_to_update_on_latest_stable_releases: { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] },
        repo_name: mock_repo_name,
        github_pr_token: mock_github_pr_token,
        github_token: mock_github_token,
        github_rate_limit: 3,
        editor: editor,
        hybrid_common_version: hybrid_common_version,
        is_prerelease: false,
        append_hybrid_common_version: append_hybrid_common_version
      )
    end

    it 'fails if append_hybrid_common_version is true and provided version metadata does not match - non-interactive' do
      # Arrange
      interactive = false
      append_hybrid_common_version = true
      mismatched_metadata = "some.metadata"
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(interactive)
      # We are providing a version with metadata that doesn't match the PHC version
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return("#{new_version}+#{mismatched_metadata}")
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)

      # Assert
      expect(FastlaneCore::UI).not_to receive(:confirm)
        .with("Would you like to append the PHC version (+#{hybrid_common_version})?")

      expect(FastlaneCore::UI).to receive(:user_error!)
        .with("Asked to append PHC version (+#{hybrid_common_version}), but the version provided already has metadata (+#{mismatched_metadata}).")
        .once
        .and_throw(:expected_error)

      # Act
      catch :expected_error do
        Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
          current_version: current_version,
          changelog_latest_path: mock_changelog_latest_path,
          changelog_path: mock_changelog_path,
          repo_name: mock_repo_name,
          github_pr_token: mock_github_pr_token,
          github_token: mock_github_token,
          github_rate_limit: 3,
          editor: editor,
          hybrid_common_version: hybrid_common_version,
          is_prerelease: false,
          append_hybrid_common_version: append_hybrid_common_version
        )
      end
    end

    it 'fails if append_hybrid_common_version is true and provided version has + but no metadata - non-interactive' do
      # Arrange
      interactive = false
      append_hybrid_common_version = true
      mismatched_metadata = "" # Empty on purpose
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(interactive)
      # We are providing a version with metadata that doesn't match the PHC version
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return("#{new_version}+#{mismatched_metadata}")
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)

      # Assert
      expect(FastlaneCore::UI).not_to receive(:confirm)
        .with("Would you like to append the PHC version (+#{hybrid_common_version})?")

      expect(FastlaneCore::UI).to receive(:user_error!)
        .with("Asked to append PHC version (+#{hybrid_common_version}), but the version provided already has metadata (+#{mismatched_metadata}).")
        .once
        .and_throw(:expected_error)

      # Act
      catch :expected_error do
        Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
          current_version: current_version,
          changelog_latest_path: mock_changelog_latest_path,
          changelog_path: mock_changelog_path,
          repo_name: mock_repo_name,
          github_pr_token: mock_github_pr_token,
          github_token: mock_github_token,
          github_rate_limit: 3,
          editor: editor,
          hybrid_common_version: hybrid_common_version,
          is_prerelease: false,
          append_hybrid_common_version: append_hybrid_common_version
        )
      end
    end

    it 'asks to append a PHC version if all conditions are met' do
      # Arrange
      new_version_appended = "#{new_version}+#{hybrid_common_version}"
      new_branch_name = "release/#{new_version_appended}"
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(true)
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return(new_version)
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)
      allow(File).to receive(:read).with(mock_changelog_latest_path).and_return(edited_changelog)
      allow(Fastlane::Helper::VersioningHelper).to receive(:auto_generate_changelog)
        .with(mock_repo_name, mock_github_token, 3, false, hybrid_common_version, nil)
        .and_return(auto_generated_changelog)
        .once
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:edit_changelog)
        .with(auto_generated_changelog, mock_changelog_latest_path, editor)
        .once

      # Assert
      expect(FastlaneCore::UI).to receive(:confirm)
        .with("Would you like to append the PHC version (+#{hybrid_common_version})?")
        .once
        .and_return(true)
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:validate_local_config_status_for_bump)
        .with(new_branch_name, mock_github_pr_token)
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:replace_version_number)
        .with(current_version,
              new_version_appended,
              { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
              { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
              { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] })
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:attach_changelog_to_master)
        .with(new_version_appended, mock_changelog_latest_path, mock_changelog_path)
        .once
      expect(Fastlane::Helper::RevenuecatInternalHelper).to receive(:create_pr)
        .with("Release/#{new_version_appended}", edited_changelog, mock_repo_name, base_branch, new_branch_name, mock_github_pr_token, labels)
        .once

      # Act
      Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
        current_version: current_version,
        changelog_latest_path: mock_changelog_latest_path,
        changelog_path: mock_changelog_path,
        files_to_update: { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
        files_to_update_without_prerelease_modifiers: { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
        files_to_update_on_latest_stable_releases: { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] },
        repo_name: mock_repo_name,
        github_pr_token: mock_github_pr_token,
        github_token: mock_github_token,
        github_rate_limit: 3,
        editor: editor,
        hybrid_common_version: hybrid_common_version,
        is_prerelease: false,
        append_hybrid_common_version: nil
      )
    end

    it 'does not ask to append a PHC version if hybrid_common_version is nil' do
      hybrid_common_version = nil
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(true)
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return(new_version)
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)
      allow(File).to receive(:read).with(mock_changelog_latest_path).and_return(edited_changelog)
      allow(Fastlane::Helper::VersioningHelper).to receive(:auto_generate_changelog)
        .with(mock_repo_name, mock_github_token, 3, false, hybrid_common_version, nil)
        .and_return(auto_generated_changelog)
        .once
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:edit_changelog)
        .with(auto_generated_changelog, mock_changelog_latest_path, editor)
        .once
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:validate_local_config_status_for_bump)
        .with(new_branch_name, mock_github_pr_token)
        .once
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:replace_version_number)
        .with(current_version,
              new_version,
              { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
              { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
              { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] })
        .once
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:attach_changelog_to_master)
        .with(new_version, mock_changelog_latest_path, mock_changelog_path)
        .once
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:create_pr)
        .with("Release/#{new_version}", edited_changelog, mock_repo_name, base_branch, new_branch_name, mock_github_pr_token, labels)
        .once

      expect(FastlaneCore::UI).not_to receive(:confirm)
        .with("Would you like to append the PHC version (+#{hybrid_common_version})?")

      Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
        current_version: current_version,
        changelog_latest_path: mock_changelog_latest_path,
        changelog_path: mock_changelog_path,
        files_to_update: { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
        files_to_update_without_prerelease_modifiers: { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
        files_to_update_on_latest_stable_releases: { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] },
        repo_name: mock_repo_name,
        github_pr_token: mock_github_pr_token,
        github_token: mock_github_token,
        github_rate_limit: 3,
        editor: editor,
        hybrid_common_version: hybrid_common_version,
        is_prerelease: false,
        append_hybrid_common_version: nil
      )
    end

    it 'does not ask to append a PHC version if hybrid_common_version is blank' do
      hybrid_common_version = " "
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(true)
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return(new_version)
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(true)
      allow(File).to receive(:read).with(mock_changelog_latest_path).and_return(edited_changelog)
      allow(Fastlane::Helper::VersioningHelper).to receive(:auto_generate_changelog)
        .with(mock_repo_name, mock_github_token, 3, false, hybrid_common_version, nil)
        .and_return(auto_generated_changelog)
        .once
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:edit_changelog)
        .with(auto_generated_changelog, mock_changelog_latest_path, editor)
        .once
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:validate_local_config_status_for_bump)
        .with(new_branch_name, mock_github_pr_token)
        .once
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:replace_version_number)
        .with(current_version,
              new_version,
              { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
              { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
              { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] })
        .once
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:attach_changelog_to_master)
        .with(new_version, mock_changelog_latest_path, mock_changelog_path)
        .once
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:create_pr)
        .with("Release/#{new_version}", edited_changelog, mock_repo_name, base_branch, new_branch_name, mock_github_pr_token, labels)
        .once

      expect(FastlaneCore::UI).not_to receive(:confirm)
        .with("Would you like to append the PHC version (+#{hybrid_common_version})?")

      Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.run(
        current_version: current_version,
        changelog_latest_path: mock_changelog_latest_path,
        changelog_path: mock_changelog_path,
        files_to_update: { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
        files_to_update_without_prerelease_modifiers: { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
        files_to_update_on_latest_stable_releases: { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] },
        repo_name: mock_repo_name,
        github_pr_token: mock_github_pr_token,
        github_token: mock_github_token,
        github_rate_limit: 3,
        editor: editor,
        hybrid_common_version: hybrid_common_version,
        is_prerelease: false,
        append_hybrid_common_version: nil
      )
    end

    def setup_stubs
      allow(Fastlane::Actions).to receive(:git_branch).and_return(base_branch)
      allow(FastlaneCore::UI).to receive(:interactive?).and_return(false)
      allow(FastlaneCore::UI).to receive(:input).with('New version number: ').and_return(new_version)
      allow(FastlaneCore::UI).to receive(:confirm).with(anything).and_return(false)
      allow(File).to receive(:read).with(mock_changelog_latest_path).and_return(edited_changelog)
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:validate_local_config_status_for_bump)
        .with('release/1.13.0', mock_github_pr_token)
      allow(Fastlane::Helper::VersioningHelper).to receive(:auto_generate_changelog)
        .with(mock_repo_name, mock_github_token, 3, false, nil, nil)
        .and_return(auto_generated_changelog)
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:write_changelog)
        .with(auto_generated_changelog, mock_changelog_latest_path)
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:create_new_branch_and_checkout)
        .with(new_branch_name)
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:replace_version_number)
        .with(current_version,
              new_version,
              { "./test_file.sh" => ['{x}'], "./test_file2.rb" => ['{x}'] },
              { "./test_file3.kt" => ['{x}'], "./test_file4.swift" => ['{x}'] },
              { "./test_file5.kt" => ['{x}'], "./test_file6.swift" => ['{x}'] })
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:attach_changelog_to_master)
        .with(new_version, mock_changelog_latest_path, mock_changelog_path)
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:commit_changes_and_push_current_branch)
        .with("Version bump for #{new_version}")
      allow(Fastlane::Helper::RevenuecatInternalHelper).to receive(:create_pr)
        .with("Release/1.13.0", edited_changelog, mock_repo_name, base_branch, new_branch_name, mock_github_pr_token, labels)
    end
  end

  describe '#available_options' do
    it 'has correct number of options' do
      expect(Fastlane::Actions::BumpVersionUpdateChangelogCreatePrAction.available_options.size).to eq(17)
    end
  end
end
