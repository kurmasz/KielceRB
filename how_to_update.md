# How to release a new version of Kielce

1. Update the version string in:
   - `lib/kielce/version.rb`, setting `(Kielce::VERSION)`

3. Add release notes to changelog.txt

4. Build and push:

   `gem build kielce.gemspec`

   `gem push kielce-*.gem`
---

Tip: After building, verify the correct gem file is produced with:

`ls -l kielce-*.gem`
