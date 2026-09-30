#!/bin/bash
# Install KielceRB from the local repository.
# To install the latest release instead, simply run: gem install kielce

set -euo pipefail

cd "$(dirname "$0")"

# Clean old builds to avoid ambiguity
rm -f kielce-*.gem

gem build kielce.gemspec
gem install kielce-*.gem
