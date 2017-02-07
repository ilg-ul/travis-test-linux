#! /bin/bash

cd "$(dirname "$0")"

export PATH="$HOME/opt/homebrew-jekyll/bin":$PATH

site="../travis-test-jekyll.git"

# Be sure the 'vendor/' folder is excluded, 
# otherwise a strage error occurs.
bundle exec jekyll build --destination "${site}"

export NOKOGIRI_USE_SYSTEM_LIBRARIES=true

# --log-level debug \

# Validate images and links (internal & external).
 bundle exec htmlproofer \
--url-ignore=""  \
"${site}"

echo
echo "Done"
