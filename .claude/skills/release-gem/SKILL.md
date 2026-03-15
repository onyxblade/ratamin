---
name: release-gem
description: Release a new version of the gem to RubyGems, update CHANGELOG.md, create a GitHub Release, and push a git tag. Use when the user wants to publish a new gem version.
argument-hint: [version]
---

Release the gem. If $ARGUMENTS is provided, that is the new version number. Otherwise read the current version from `lib/ratamin/version.rb`.

Steps:

1. **Confirm version**: Read `lib/ratamin/version.rb`. If $ARGUMENTS differs from the current version, update the file and commit the change.

2. **Run tests**: `bundle exec rspec` — abort if any tests fail.

3. **Update CHANGELOG.md**: Add a new section for this version at the top (below the `## [Unreleased]` header if present), using Keep a Changelog format:
   ```
   ## [X.Y.Z] - YYYY-MM-DD
   ### Added / Changed / Fixed
   - ...
   ```
   Ask the user what to put in the changelog if there is nothing obvious from recent commits. Commit the changelog update together with any version bump.

4. **Build the gem**: `gem build ratamin.gemspec`

5. **Push to RubyGems**: `gem push ratamin-X.Y.Z.gem`

6. **Create git tag**: `git tag vX.Y.Z`

7. **Push commits and tag**: `git push origin main --tags`

8. **Create GitHub Release**: Extract the release notes for this version from CHANGELOG.md and run:
   ```
   gh release create vX.Y.Z --title "vX.Y.Z" --notes-file <(extracted notes)
   ```

Report the RubyGems page and GitHub Release URL when done.
