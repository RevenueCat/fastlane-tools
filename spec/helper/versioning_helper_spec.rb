describe Fastlane::Helper::VersioningHelper do
  describe '.auto_generate_changelog' do
    let(:server_url) { 'https://api.github.com' }
    let(:http_method) { 'GET' }
    let(:get_commits_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/get_commits_since_last_release.json") }
    end
    let(:get_commit_1_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/get_commit_sha_a72c0435ecf71248f311900475e881cc07ac2eaf.json") }
    end
    let(:get_commit_2_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/get_commit_sha_0e67cdb1c7582ce3e2fd00367acc24db6242c6d6.json") }
    end
    let(:get_commit_3_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/get_commit_sha_cfdd80f73d8c91121313d72227b4cbe283b57c1e.json") }
    end
    let(:duplicate_items_get_commit_2_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/duplicate_items_get_commit_sha_0e67cdb1c7582ce3e2fd00367acc24db6242c6d6.json") }
    end
    let(:breaking_get_commit_1_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/breaking_get_commit_sha_a72c0435ecf71248f311900475e881cc07ac2eaf.json") }
    end
    let(:no_label_get_commit_1_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/no_label_get_commit_sha_a72c0435ecf71248f311900475e881cc07ac2eaf.json") }
    end

    let(:hashes_to_responses) do
      {
        'a72c0435ecf71248f311900475e881cc07ac2eaf' => get_commit_1_response,
        '0e67cdb1c7582ce3e2fd00367acc24db6242c6d6' => get_commit_2_response,
        'cfdd80f73d8c91121313d72227b4cbe283b57c1e' => get_commit_3_response
      }
    end

    it 'generates changelog automatically from github commits' do
      setup_commit_search_stubs(hashes_to_responses)
      expect_any_instance_of(Object).not_to receive(:sleep)
      changelog = Fastlane::Helper::VersioningHelper.auto_generate_changelog(
        'mock-repo-name',
        'mock-github-token',
        0
      )
      expect(changelog).to eq("### Bugfixes\n" \
                              "* Fix replace version without prerelease modifiers (#1751) via Toni Rico (@tonidero)\n" \
                              "### New Features\n" \
                              "* added a log when `autoSyncPurchases` is disabled (#1749) via aboedo (@aboedo)\n" \
                              "### Other Changes\n" \
                              "* Prepare next version: 4.8.0-SNAPSHOT (#1750) via RevenueCat Releases (@revenuecat-ops)")
    end

    it 'sleeps between getting commits info if passing rate limit sleep' do
      setup_commit_search_stubs(hashes_to_responses)
      expect_any_instance_of(Object).to receive(:sleep).with(3).exactly(3).times
      changelog = Fastlane::Helper::VersioningHelper.auto_generate_changelog(
        'mock-repo-name',
        'mock-github-token',
        3
      )
      expect(changelog).to eq("### Bugfixes\n" \
                              "* Fix replace version without prerelease modifiers (#1751) via Toni Rico (@tonidero)\n" \
                              "### New Features\n" \
                              "* added a log when `autoSyncPurchases` is disabled (#1749) via aboedo (@aboedo)\n" \
                              "### Other Changes\n" \
                              "* Prepare next version: 4.8.0-SNAPSHOT (#1750) via RevenueCat Releases (@revenuecat-ops)")
    end

    it 'fails if it finds multiple commits with same sha' do
      setup_commit_search_stubs(hashes_to_responses)
      allow(Fastlane::Actions::GithubApiAction).to receive(:run)
        .with(server_url: server_url,
              path: '/search/issues?q=repo:RevenueCat/mock-repo-name+is:pr+base:main+SHA:0e67cdb1c7582ce3e2fd00367acc24db6242c6d6',
              http_method: http_method,
              body: {},
              api_token: 'mock-github-token')
        .and_return(duplicate_items_get_commit_2_response)
      expect do
        Fastlane::Helper::VersioningHelper.auto_generate_changelog(
          'mock-repo-name',
          'mock-github-token',
          0
        )
      end.to raise_exception(StandardError)
    end

    it 'breaking fix is added to breaking changes section' do
      setup_commit_search_stubs(hashes_to_responses)
      allow(Fastlane::Actions::GithubApiAction).to receive(:run)
        .with(server_url: server_url,
              path: '/search/issues?q=repo:RevenueCat/mock-repo-name+is:pr+base:main+SHA:a72c0435ecf71248f311900475e881cc07ac2eaf',
              http_method: http_method,
              body: {},
              api_token: 'mock-github-token')
        .and_return(breaking_get_commit_1_response)
      expect_any_instance_of(Object).not_to receive(:sleep)
      changelog = Fastlane::Helper::VersioningHelper.auto_generate_changelog(
        'mock-repo-name',
        'mock-github-token',
        0
      )
      expect(changelog).to eq("### Breaking Changes\n" \
                              "* added a log when `autoSyncPurchases` is disabled (#1749) via aboedo (@aboedo)\n" \
                              "### Bugfixes\n" \
                              "* Fix replace version without prerelease modifiers (#1751) via Toni Rico (@tonidero)\n" \
                              "### Other Changes\n" \
                              "* Prepare next version: 4.8.0-SNAPSHOT (#1750) via RevenueCat Releases (@revenuecat-ops)")
    end

    it 'change is classified as Other Changes if pr has no label' do
      setup_commit_search_stubs(hashes_to_responses)
      allow(Fastlane::Actions::GithubApiAction).to receive(:run)
        .with(server_url: server_url,
              path: '/search/issues?q=repo:RevenueCat/mock-repo-name+is:pr+base:main+SHA:a72c0435ecf71248f311900475e881cc07ac2eaf',
              http_method: http_method,
              body: {},
              api_token: 'mock-github-token')
        .and_return(no_label_get_commit_1_response)
      expect_any_instance_of(Object).not_to receive(:sleep)
      changelog = Fastlane::Helper::VersioningHelper.auto_generate_changelog(
        'mock-repo-name',
        'mock-github-token',
        0
      )
      expect(changelog).to eq("### Bugfixes\n" \
                              "* Fix replace version without prerelease modifiers (#1751) via Toni Rico (@tonidero)\n" \
                              "### Other Changes\n" \
                              "* Prepare next version: 4.8.0-SNAPSHOT (#1750) via RevenueCat Releases (@revenuecat-ops)\n" \
                              "* added a log when `autoSyncPurchases` is disabled (#1749) via aboedo (@aboedo)")
    end
  end

  describe '.determine_next_version_using_labels' do
    let(:repo_name) { 'purchases-ios' }
    let(:server_url) { 'https://api.github.com' }
    let(:http_method) { 'GET' }
    let(:get_commits_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/get_commits_since_last_release.json") }
    end
    let(:get_commits_response_patch) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/get_commits_since_last_release_patch_changes.json") }
    end
    let(:get_feat_commit_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/get_commit_sha_a72c0435ecf71248f311900475e881cc07ac2eaf.json") }
    end
    let(:get_fix_commit_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/get_commit_sha_0e67cdb1c7582ce3e2fd00367acc24db6242c6d6.json") }
    end
    let(:get_next_release_commit_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/get_commit_sha_cfdd80f73d8c91121313d72227b4cbe283b57c1e.json") }
    end
    let(:get_breaking_commit_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/breaking_get_commit_sha_a72c0435ecf71248f311900475e881cc07ac2eaf.json") }
    end
    let(:get_ci_commit_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/get_commit_sha_819dc620db5608fb952c852038a3560554161707.json") }
    end
    let(:get_build_commit_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/get_commit_sha_7d77decbcc9098145d1efd4c2de078b6121c8906.json") }
    end
    let(:get_refactor_commit_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/get_commit_sha_6d37c766b6da55dcab67c201c93ba3d4ca538e55.json") }
    end
    let(:get_duplicate_items_fix_commit_response) do
      { body: File.read("#{File.dirname(__FILE__)}/../test_files/duplicate_items_get_commit_sha_0e67cdb1c7582ce3e2fd00367acc24db6242c6d6.json") }
    end

    let(:hashes_to_responses) do
      {
        'a72c0435ecf71248f311900475e881cc07ac2eaf' => get_feat_commit_response,
        '0e67cdb1c7582ce3e2fd00367acc24db6242c6d6' => get_fix_commit_response,
        'cfdd80f73d8c91121313d72227b4cbe283b57c1e' => get_next_release_commit_response,
        '819dc620db5608fb952c852038a3560554161707' => get_ci_commit_response,
        '7d77decbcc9098145d1efd4c2de078b6121c8906' => get_build_commit_response,
        '6d37c766b6da55dcab67c201c93ba3d4ca538e55' => get_refactor_commit_response
      }
    end

    it 'determines next version as patch correctly' do
      setup_commit_search_stubs(hashes_to_responses)

      allow(Fastlane::Actions::GithubApiAction).to receive(:run)
        .with(server_url: server_url,
              path: '/repos/RevenueCat/mock-repo-name/compare/1.11.0...HEAD',
              http_method: http_method,
              body: {},
              api_token: 'mock-github-token')
        .and_return(get_commits_response_patch)
      expect_any_instance_of(Object).not_to receive(:sleep)
      next_version = Fastlane::Helper::VersioningHelper.determine_next_version_using_labels(
        'mock-repo-name',
        'mock-github-token',
        0
      )
      expect(next_version).to eq("1.11.1")
    end

    it 'determines next version as minor correctly' do
      setup_commit_search_stubs(hashes_to_responses)

      expect_any_instance_of(Object).not_to receive(:sleep)
      next_version = Fastlane::Helper::VersioningHelper.determine_next_version_using_labels(
        'mock-repo-name',
        'mock-github-token',
        0
      )
      expect(next_version).to eq("1.12.0")
    end

    it 'determines next version as major correctly' do
      setup_commit_search_stubs(hashes_to_responses)

      allow(Fastlane::Actions::GithubApiAction).to receive(:run)
        .with(server_url: server_url,
              path: '/search/issues?q=repo:RevenueCat/mock-repo-name+is:pr+base:main+SHA:a72c0435ecf71248f311900475e881cc07ac2eaf',
              http_method: http_method,
              body: {},
              api_token: 'mock-github-token')
        .and_return(get_breaking_commit_response)
      expect_any_instance_of(Object).not_to receive(:sleep)
      next_version = Fastlane::Helper::VersioningHelper.determine_next_version_using_labels(
        'mock-repo-name',
        'mock-github-token',
        0
      )
      expect(next_version).to eq("2.0.0")
    end

    it 'sleeps between getting commits info if passing rate limit sleep' do
      setup_commit_search_stubs(hashes_to_responses)

      expect_any_instance_of(Object).to receive(:sleep).with(3).exactly(3).times
      next_version = Fastlane::Helper::VersioningHelper.determine_next_version_using_labels(
        'mock-repo-name',
        'mock-github-token',
        3
      )
      expect(next_version).to eq("1.12.0")
    end

    it 'fails if it finds multiple commits with same sha' do
      setup_commit_search_stubs(hashes_to_responses)

      allow(Fastlane::Actions::GithubApiAction).to receive(:run)
        .with(server_url: server_url,
              path: '/search/issues?q=repo:RevenueCat/mock-repo-name+is:pr+base:main+SHA:0e67cdb1c7582ce3e2fd00367acc24db6242c6d6',
              http_method: http_method,
              body: {},
              api_token: 'mock-github-token')
        .and_return(get_duplicate_items_fix_commit_response)
      expect do
        Fastlane::Helper::VersioningHelper.determine_next_version_using_labels(
          'mock-repo-name',
          'mock-github-token',
          0
        )
      end.to raise_exception(StandardError)
    end
  end

  describe '.increase_version' do
    it 'increases patch version number' do
      next_version = Fastlane::Helper::VersioningHelper.increase_version('1.2.3', :patch, false)
      expect(next_version).to eq('1.2.4')
    end

    it 'increases minor version number' do
      next_version = Fastlane::Helper::VersioningHelper.increase_version('1.2.3', :minor, false)
      expect(next_version).to eq('1.3.0')
    end

    it 'increases major version number' do
      next_version = Fastlane::Helper::VersioningHelper.increase_version('1.2.3', :major, false)
      expect(next_version).to eq('2.0.0')
    end

    it 'increases minor snapshot version number' do
      next_version = Fastlane::Helper::VersioningHelper.increase_version('1.2.3', :minor, true)
      expect(next_version).to eq('1.3.0-SNAPSHOT')
    end

    it 'increases major snapshot version number' do
      next_version = Fastlane::Helper::VersioningHelper.increase_version('1.2.3', :major, true)
      expect(next_version).to eq('2.0.0-SNAPSHOT')
    end
  end

  def setup_commit_search_stubs(hashes_to_responses)
    allow(Fastlane::Actions).to receive(:sh).with('git fetch --tags')
    allow(Fastlane::Actions).to receive(:sh)
      .with("git describe --tags $(git rev-list --exclude=\"*[a-zA-Z]*\" --tags=\"[0-9]*.[0-9]*.*[0-9]\" --max-count=1)")
      .and_return('1.11.0')
    allow(Fastlane::Actions::GithubApiAction).to receive(:run)
      .with(server_url: server_url,
            path: '/repos/RevenueCat/mock-repo-name/compare/1.11.0...HEAD',
            http_method: http_method,
            body: {},
            api_token: 'mock-github-token')
      .and_return(get_commits_response)
    hashes_to_responses.each do |hash, response|
      allow(Fastlane::Actions::GithubApiAction).to receive(:run)
        .with(server_url: server_url,
              path: "/search/issues?q=repo:RevenueCat/mock-repo-name+is:pr+base:main+SHA:#{hash}",
              http_method: http_method,
              body: {},
              api_token: 'mock-github-token')
        .and_return(response)
    end
  end
end