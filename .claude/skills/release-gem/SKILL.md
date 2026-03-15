---
name: release-gem
description: Release a new version of the gem to RubyGems, update CHANGELOG.md, create a GitHub Release, and push a git tag. Use when the user wants to publish a new gem version.
argument-hint: [version]
---

Release the gem. If $ARGUMENTS is provided, that is the new version number. Otherwise read the current version from `lib/ratamin/version.rb`.

Steps:

1. **Confirm version**: Read `lib/ratamin/version.rb`. If $ARGUMENTS differs from the current version, update the file.

2. **Bundle**: Run `bundle` to update `Gemfile.lock` with the new version, then commit `lib/ratamin/version.rb` and `Gemfile.lock` together.

3. **Run tests**: `bundle exec rspec` — abort if any tests fail.

4. **Update CHANGELOG.md**: Add a new section for this version at the top (below the `## [Unreleased]` header if present), using Keep a Changelog format:
   ```
   ## [X.Y.Z] - YYYY-MM-DD
   ### Added / Changed / Fixed
   - ...
   ```
   Ask the user what to put in the changelog if there is nothing obvious from recent commits. Commit the changelog update.

5. **Build the gem**: `gem build ratamin.gemspec`

6. **Push to RubyGems**: `gem push ratamin-X.Y.Z.gem`

7. **Create git tag**: `git tag vX.Y.Z`

8. **Push commits and tag**: `git push origin main --tags`

9. **Create GitHub Release**: Extract the release notes for this version from CHANGELOG.md and run:
   ```
   gh release create vX.Y.Z --title "vX.Y.Z" --notes-file <(extracted notes)
   ```

Report the RubyGems page and GitHub Release URL when done.
