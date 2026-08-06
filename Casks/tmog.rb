cask "tmog" do
  version "0.1.0,20260731155640"
  sha256 "836b35dd941b92fdad609f835390953b8db13d86878c44a0e2083525ac5fb5ec"

  url "https://www.tmog.org/downloads/TMOG-Task-Manager-#{version.csv.first}-#{version.csv.second}-macOS-universal.dmg"
  name "Task Manager TMOG"
  desc "Native system monitor for CPU, memory, storage, network, and thermals"
  homepage "https://www.tmog.org/"

  livecheck do
    url "https://www.tmog.org/downloads/release.json"
    strategy :json do |json|
      next if json["version"].blank?

      json["build"].present? ? "#{json["version"]},#{json["build"]}" : json["version"]
    end
  end

  depends_on macos: :ventura

  app "Task Manager TMOG.app"

  uninstall quit: "com.tmog.taskmanager"

  zap trash: [
    "~/Library/Caches/com.tmog.taskmanager",
    "~/Library/HTTPStorages/com.tmog.taskmanager",
    "~/Library/Preferences/com.tmog.taskmanager.plist",
    "~/Library/Saved Application State/com.tmog.taskmanager.savedState",
  ]
end
