cask "tmog" do
  version "1.0.0,20260923234339"
  sha256 "78c482e598e16fa5b479e05a9609a3a4c1f78dfce960468bea77f0fb98189895"

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

  depends_on macos: :sonoma

  app "Task Manager TMOG.app"

  uninstall quit: "com.tmog.taskmanager"

  zap trash: [
    "~/Library/Caches/com.tmog.taskmanager",
    "~/Library/HTTPStorages/com.tmog.taskmanager",
    "~/Library/Preferences/com.tmog.taskmanager.plist",
    "~/Library/Saved Application State/com.tmog.taskmanager.savedState",
  ]
end
