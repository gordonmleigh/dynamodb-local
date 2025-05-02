#!/bin/bash
set -e

install_path="$HOME/dynamodb-local"
bin_path="$install_path/bin"

tarball_name="dynamodb_local_latest.tar.gz"
install_script_source="https://raw.githubusercontent.com/gordonmleigh/dynamodb-local/refs/heads/main/install.sh"

app_identifier="local.dynamodb"
source_url="https://d1ni2b6xgvw0s0.cloudfront.net/v2.x/$tarball_name"
checksum_url="https://d1ni2b6xgvw0s0.cloudfront.net/v2.x/$tarball_name.sha256"

checksum_path="$install_path/checksum.sha256"
install_script_path="$install_path/install.sh"
plist_path="$HOME/Library/LaunchAgents/$app_identifier.plist"
tarball_path="$install_path/$tarball_name"
wrapper_path="$install_path/dynamodb-local"


bootstrap() {
  mkdir -p "$install_path"
  curl -sL "$install_script_source" -o "$install_script_path"
  update
  install_wrapper
  install_service
}

install_wrapper() {
  cat > "$wrapper_path" <<EOF
#!/bin/bash
cd "$install_path" # so that default data folder is the current path
java "-Djava.library.path=$bin_path/DynamoDBLocal_lib" -jar "$bin_path/DynamoDBLocal.jar" "$@"
EOF
  chmod +x "$wrapper_path"
}

install_service() {
  use_shared="Y"

  if [ -t 0 ]; then
    read -p "Use shared dynamodb-local instance? (Y/n) " use_shared
  fi
  
  if [ "$use_shared" != "n" ]; then 
    extra_service_args="<string>-sharedDb</string>"
  fi

  echo "Saving plist to $plist_path..."
  cat > "$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>$app_identifier</string>
    <key>Program</key>
    <string>$wrapper_path</string>
    <key>ProgramArguments</key>
    <array>
      <string>$wrapper_path</string>
      $extra_service_args
    </array>
    <key>KeepAlive</key>
    <true/>
  </dict>
</plist>
EOF

  echo "Installing service $app_identifier..."
  launchctl bootstrap "gui/$UID" "$plist_path"
  launchctl kickstart -k "gui/$UID/$app_identifier"
}

uninstall_service() {
  echo "Removing service $app_identifier..."
  launchctl bootout "gui/$UID/$app_identifier" || true
  rm "$plist_path" || true
}

update() {
  echo "Updating dynamodb-local"
  mkdir -p "$bin_path"

  echo "Fetching binaries from $source_url..."
  curl -s -o "$tarball_path" -z "$tarball_path" "$source_url"

  echo "Validating checksum..."
  curl -s -o "$checksum_path" -z "$checksum_path" "$checksum_url"
  (cd "$install_path" && sha256sum -c "$checksum_path")

  echo "Extracting..."
  tar -zxf "$tarball_path" -C "$bin_path"
}

if [ "$1" == "uninstall" ]; then
  uninstall_service
elif [ -f "$install_script_path" ]; then
  # we are already bootstrapped
  update
  uninstall_service
  install_service
else
  echo "Installing dynamodb-local to $install_path"
  bootstrap
fi
