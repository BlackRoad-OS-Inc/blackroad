Last login: Fri Dec 12 14:46:46 on ttys013
notify () {
        if [[ $# -eq 0 ]]
        then
                cat <<EOF
Usage: notify [--shortcut NameOfShortcut] [--url https://url.to.open/] [title] <body> ...
Examples:
  notify "BlackRoad" "All services started!"
  notify --url https://blackroad.io "Deployment Complete" "13 services running"
  notify --shortcut "CheckStatus" "System Alert" "Review needed"
EOF
                return 0
        fi
        local key=487ccb7f82cc43f97e49de65bcdd6aeee2151920a94e596867623a8b17454c7e 
        local user=f78fAbfd4TCWKyMp4B4pVmyINVKNJTmwVpKGJapc 
        local iv=ab5bbeb426015da7eedcee8bee3dffb7 
        local plain=$(
  echo Secure ShellFish Notify 2.0
  for var in "$@"
  do
    echo -ne "$var" | base64
  done) 
        local base64=$(echo "$plain" | openssl enc -aes-256-cbc -base64 -K $key -iv $iv) 
        curl -sS -X POST -H "Content-Type: text/plain" --data "$base64" "https://secureshellfish.app/push/?user=$user&mutable"
}
widget () {
        if [[ $# -eq 0 ]]
        then
                cat <<EOF
Usage: widget [target] <data> ...
Update widget on device from which this function was installed.
Supports: string, progress, icon, target, color, url, shortcut
Examples:
  widget "BlackRoad Status" "13 services running" "checkmark.circle.fill" "#0066FF"
  widget --progress "50%" "Deployment" "arrow.up.circle"
  widget --url https://blackroad.io "Visit Site"
EOF
                return 0
        fi
        local key=487ccb7f82cc43f97e49de65bcdd6aeee2151920a94e596867623a8b17454c7e 
        local user=f78fAbfd4TCWKyMp4B4pVmyINVKNJTmwVpKGJapc 
        local iv=ab5bbeb426015da7eedcee8bee3dffb7 
        local plain=$(
  echo Secure ShellFish Widget 2.0
  for var in "$@"
  do
    echo -ne "$var" | base64
  done) 
        local base64=$(echo "$plain" | openssl enc -aes-256-cbc -base64 -K $key -iv $iv) 
        curl -sS -X POST -H "Content-Type: text/plain" --data "$base64" "https://secureshellfish.app/push/?user=$user"
}
wc_open () {
        if [[ $# -eq 0 ]]
        then
                cat <<EOF
Usage: wc_open [repo-name]
Open Working Copy app, optionally to a specific repository.
EOF
                return 0
        fi
        local repo=$(echo "$1" | sed 's/ /%20/g') 
        openUrl "working-copy://open?repo=$repo"
}
wc_clone () {
        if [[ $# -lt 1 ]]
        then
                cat <<EOF
Usage: wc_clone <git-url> [branch]
Clone a repository in Working Copy.
EOF
                return 0
        fi
        local url=$(echo "$1" | sed 's/ /%20/g') 
        local branch="${2:-main}" 
        openUrl "working-copy://clone?remote=$url&branch=$branch"
}
wc_pull () {
        if [[ $# -eq 0 ]]
        then
                cat <<EOF
Usage: wc_pull <repo-name>
Pull latest changes in Working Copy repository.
EOF
                return 0
        fi
        local repo=$(echo "$1" | sed 's/ /%20/g') 
        openUrl "working-copy://pull?repo=$repo"
}
wc_push () {
        if [[ $# -eq 0 ]]
        then
                cat <<EOF
Usage: wc_push <repo-name>
Push commits in Working Copy repository.
EOF
                return 0
        fi
        local repo=$(echo "$1" | sed 's/ /%20/g') 
        openUrl "working-copy://push?repo=$repo"
}
wc_commit () {
        if [[ $# -lt 2 ]]
        then
                cat <<EOF
Usage: wc_commit <repo-name> <message>
Create commit in Working Copy.
EOF
                return 0
        fi
        local repo=$(echo "$1" | sed 's/ /%20/g') 
        shift
        local message=$(echo "$*" | sed 's/ /%20/g') 
        openUrl "working-copy://commit?repo=$repo&message=$message"
}
wc_sync () {
        if [[ $# -eq 0 ]]
        then
                cat <<EOF
Usage: wc_sync <repo-name>
Full sync (pull + push) in Working Copy.
EOF
                return 0
        fi
        local repo="$1" 
        wc_pull "$repo"
        sleep 1
        wc_push "$repo"
}
gh_app () {
        if [[ $# -eq 0 ]]
        then
                cat <<EOF
Usage: gh_app [owner/repo]
Open GitHub app, optionally to a specific repository.
EOF
                return 0
        fi
        openUrl "github://repository/$1"
}
gh_pr () {
        if [[ $# -lt 2 ]]
        then
                cat <<EOF
Usage: gh_pr <owner/repo> <pr-number>
Open pull request in GitHub app.
EOF
                return 0
        fi
        openUrl "github://repository/$1/pull/$2"
}
gh_issue () {
        if [[ $# -lt 2 ]]
        then
                cat <<EOF
Usage: gh_issue <owner/repo> <issue-number>
Open issue in GitHub app.
EOF
                return 0
        fi
        openUrl "github://repository/$1/issues/$2"
}
safari () {
        if [[ $# -eq 0 ]]
        then
                echo "Usage: safari <url>"
                return 0
        fi
        openUrl "$1"
}
safari_reading_list () {
        if [[ $# -eq 0 ]]
        then
                echo "Usage: safari_reading_list <url>"
                return 0
        fi
        openUrl "safari-reading-list:$1"
}
notes_new () {
        if [[ $# -eq 0 ]]
        then
                cat <<EOF
Usage: notes_new <note-text>
Create new note in Apple Notes.
EOF
                return 0
        fi
        local text=$(echo "$*" | sed 's/ /%20/g') 
        openUrl "mobilenotes://create?text=$text"
}
notes_open () {
        openUrl "mobilenotes://"
}
reminder () {
        if [[ $# -eq 0 ]]
        then
                cat <<EOF
Usage: reminder <reminder-text>
Create new reminder in Apple Reminders.
EOF
                return 0
        fi
        local text=$(echo "$*" | sed 's/ /%20/g') 
        openUrl "x-apple-reminderkit://REMCDReminder/$text"
}
calendar_new () {
        if [[ $# -eq 0 ]]
        then
                cat <<EOF
Usage: calendar_new <event-title>
Create new calendar event.
EOF
                return 0
        fi
        local title=$(echo "$*" | sed 's/ /%20/g') 
        openUrl "calshow://?title=$title"
}
calendar_open () {
        openUrl "calshow://"
}
mail_compose () {
        if [[ $# -eq 0 ]]
        then
                cat <<EOF
Usage: mail_compose [to-email] [subject]
Compose new email in Mail app.
EOF
                return 0
        fi
        local to="${1:-}" 
        local subject="${2:-}" 
        openUrl "mailto:$to?subject=$(echo $subject | sed 's/ /%20/g')"
}
slack_open () {
        if [[ $# -eq 0 ]]
        then
                openUrl "slack://"
        else
                openUrl "slack://channel?team=$1"
        fi
}
slack_dm () {
        if [[ $# -eq 0 ]]
        then
                echo "Usage: slack_dm <user-id>"
                return 0
        fi
        openUrl "slack://user?team=$1"
}
discord_open () {
        if [[ $# -eq 0 ]]
        then
                openUrl "discord://"
        else
                openUrl "discord://channels/$1"
        fi
}
telegram_open () {
        if [[ $# -eq 0 ]]
        then
                openUrl "telegram://"
        else
                openUrl "tg://resolve?domain=$1"
        fi
}
notion_open () {
        if [[ $# -eq 0 ]]
        then
                openUrl "notion://"
        else
                openUrl "notion://$1"
        fi
}
obsidian_open () {
        if [[ $# -eq 0 ]]
        then
                openUrl "obsidian://"
        else
                openUrl "obsidian://open?vault=$1"
        fi
}
obsidian_new () {
        if [[ $# -lt 2 ]]
        then
                cat <<EOF
Usage: obsidian_new <vault> <note-name>
Create new note in Obsidian vault.
EOF
                return 0
        fi
        openUrl "obsidian://new?vault=$1&name=$2"
}
bear_new () {
        if [[ $# -eq 0 ]]
        then
                echo "Usage: bear_new <note-text>"
                return 0
        fi
        local text=$(echo "$*" | sed 's/ /%20/g') 
        openUrl "bear://x-callback-url/create?text=$text"
}
bear_open () {
        openUrl "bear://"
}
drafts_new () {
        if [[ $# -eq 0 ]]
        then
                echo "Usage: drafts_new <text>"
                return 0
        fi
        local text=$(echo "$*" | sed 's/ /%20/g') 
        openUrl "drafts://x-callback-url/create?text=$text"
}
things_new () {
        if [[ $# -eq 0 ]]
        then
                echo "Usage: things_new <task-title>"
                return 0
        fi
        local title=$(echo "$*" | sed 's/ /%20/g') 
        openUrl "things:///add?title=$title"
}
things_show () {
        if [[ $# -eq 0 ]]
        then
                openUrl "things:///"
        else
                openUrl "things:///show?id=$1"
        fi
}
todoist_new () {
        if [[ $# -eq 0 ]]
        then
                echo "Usage: todoist_new <task-content>"
                return 0
        fi
        local content=$(echo "$*" | sed 's/ /%20/g') 
        openUrl "todoist://addtask?content=$content"
}
trello_open () {
        if [[ $# -eq 0 ]]
        then
                openUrl "trello://"
        else
                openUrl "trello://x-callback-url/showBoard?board_id=$1"
        fi
}
onepassword_search () {
        if [[ $# -eq 0 ]]
        then
                openUrl "onepassword://"
        else
                local query=$(echo "$*" | sed 's/ /%20/g') 
                openUrl "onepassword://search/$query"
        fi
}
stripe_dashboard () {
        openUrl "stripe://dashboard"
}
testflight_open () {
        if [[ $# -eq 0 ]]
        then
                openUrl "itms-beta://"
        else
                openUrl "itms-beta://testflight.apple.com/join/$1"
        fi
}
pythonista_run () {
        if [[ $# -eq 0 ]]
        then
                echo "Usage: pythonista_run <script-name>"
                return 0
        fi
        openUrl "pythonista://run?script=$1"
}
playjs_run () {
        if [[ $# -eq 0 ]]
        then
                echo "Usage: playjs_run <project-name>"
                return 0
        fi
        openUrl "playjs://run?project=$1"
}
juno_open () {
        openUrl "juno://"
}
xcode_open () {
        openUrl "xcode://"
}
br_deploy_ios () {
        notify "BlackRoad Deploy" "Starting deployment from iPhone..."
        wc_open "blackroad-sandbox"
        sleep 2
        wc_pull "blackroad-sandbox"
}
br_status_ios () {
        local services=$(lsof -i -P 2>/dev/null | grep LISTEN | grep Python | wc -l | xargs) 
        notify "BlackRoad Status" "$services services running"
        widget "BlackRoad" "$services services" "server.rack" "#0066FF"
}
br_commit_ios () {
        if [[ $# -eq 0 ]]
        then
                echo "Usage: br_commit_ios <message>"
                return 0
        fi
        local repo_name=$(basename "$PWD") 
        notify "Git Commit" "Committing to $repo_name"
        wc_commit "$repo_name" "$*"
        sleep 1
        wc_push "$repo_name"
        notify "Git Push" "Pushed to $repo_name"
}
br_dashboards_ios () {
        safari "https://blackroad.io"
        sleep 1
        safari "https://app.blackroad.io"
        sleep 1
        safari "https://lucidia.earth"
        notify "Dashboards" "Opened all BlackRoad dashboards"
}
br_pr_ios () {
        if [[ $# -lt 2 ]]
        then
                echo "Usage: br_pr_ios <repo> <pr-number>"
                return 0
        fi
        gh_pr "BlackRoad-OS/$1" "$2"
}
ios_apps_list () {
        cat <<EOF
📱 BlackRoad iOS App Integration - Available Apps
GIT & VERSION CONTROL:
  wc_open, wc_clone, wc_pull, wc_push, wc_commit, wc_sync
  gh_app, gh_pr, gh_issue
BROWSERS:
  safari, safari_reading_list
APPLE APPS:
  notes_new, notes_open
  reminder
  calendar_new, calendar_open
  mail_compose
COMMUNICATION:
  slack_open, slack_dm
  discord_open
  telegram_open
PRODUCTIVITY:
  notion_open
  obsidian_open, obsidian_new
  bear_new, bear_open
  drafts_new
TASK MANAGEMENT:
  things_new, things_show
  todoist_new
  trello_open
DEVELOPMENT:
  pythonista_run, pythonista_open
  playjs_run
  juno_open
  xcode_open
  testflight_open
UTILITIES:
  onepassword_search
  stripe_dashboard, stripe_customers, stripe_payments
  analytics_open
BLACKROAD WORKFLOWS:
  br_deploy_ios
  br_status_ios
  br_commit_ios
  br_dashboards_ios
  br_pr_ios
Use any function with no args to see usage help.
EOF
}
✅ BlackRoad iOS Apps Integration Loaded (50+ functions)
alexa@Alexas-MacBook-Pro-2 blackroad-sandbox % find ~ -name "node_modules" -type d -prune -exec du -sh {} \; | sort -h
find: /Users/alexa/Library/Application Support/CallHistoryTransactions: Operation not permitted
find: /Users/alexa/Library/Application Support/CloudDocs/session/db: Operation not permitted
find: /Users/alexa/Library/Application Support/com.apple.sharedfilelist: Operation not permitted
find: /Users/alexa/Library/Application Support/Knowledge: Operation not permitted
find: /Users/alexa/Library/Application Support/com.apple.TCC: Operation not permitted
find: /Users/alexa/Library/Application Support/FileProvider: Operation not permitted
find: /Users/alexa/Library/Application Support/FaceTime: Operation not permitted
find: /Users/alexa/Library/Application Support/com.apple.avfoundation/Frecents: Operation not permitted
find: /Users/alexa/Library/Application Support/CallHistoryDB: Operation not permitted
find: /Users/alexa/Library/Assistant/SiriVocabulary: Operation not permitted
find: /Users/alexa/Library/Daemon Containers: Operation not permitted
find: /Users/alexa/Library/Autosave Information: Operation not permitted
find: /Users/alexa/Library/IdentityServices: Operation not permitted
find: /Users/alexa/Library/Calendars: Operation not permitted
find: /Users/alexa/Library/Messages: Operation not permitted
find: /Users/alexa/Library/HomeKit: Operation not permitted
find: /Users/alexa/Library/Sharing: Operation not permitted
find: /Users/alexa/Library/com.apple.aiml.instrumentation: Operation not permitted
find: /Users/alexa/Library/Mail: Operation not permitted
find: /Users/alexa/Library/Trial: Operation not permitted
find: /Users/alexa/Library/AppleMediaServices: Operation not permitted
find: /Users/alexa/Library/DuetExpertCenter: Operation not permitted
find: /Users/alexa/Library/Accounts: Operation not permitted
find: /Users/alexa/Library/Safari: Operation not permitted
find: /Users/alexa/Library/Biome: Operation not permitted
find: /Users/alexa/Library/IntelligencePlatform: Operation not permitted
find: /Users/alexa/Library/Shortcuts: Operation not permitted
find: /Users/alexa/Library/Suggestions: Operation not permitted
find: /Users/alexa/Library/Weather: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.accessibility.voicebanking: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.stocks: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.VoiceMemos.shared: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.secure-control-center-preferences: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.chronod: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.private.translation: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.calendar: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.testflight: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.newsd: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.siri.userfeedbacklearning: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.gamecenter: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.tips: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.spotlight: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.sharingd: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.weather: Operation not permitted
find: /Users/alexa/Library/Group Containers/com.apple.systempreferences.cache: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.feedbacklogger: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.notes: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.tipsnext: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.Safari.SandboxBroker: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.transparency: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.reminders: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.mail: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.DeviceActivity: Operation not permitted
find: /Users/alexa/Library/Group Containers/com.apple.Home.group: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.iCloudDrive: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.Photos.PhotosFileProvider: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.AppleSpell: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.mlhost: Operation not permitted
find: /Users/alexa/Library/Group Containers/group.com.apple.PegasusConfiguration: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.CloudPhotosConfiguration/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.PressAndHold/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.siri.SiriPrivateLearningAnalytics.SiriUserSegmentation/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.VoiceMemos: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.mlhost.TelemetryWorker/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.ax.KonaTTSSupport.KonaSynthesizer/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.CoreDevice.remotepairingd/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.Notes.LPPreviewGenerator/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish.upload/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.archiveutility: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.ScreenTimeAgent/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.LighthouseBitacoraFramework.BitacoraWorker/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.speech.MacinTalkFramework.WardaSynthesizer.x86-64/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.weather.widget/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.photos.ImageConversionService/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.Photos.PhotosFileProvider/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.quicklook.QuickLookUIService/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.iCal.CalendarWidgetExtension/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.contacts.donation-agent/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.photolibraryd/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.siri.media-indexer/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.speech.MacinTalkFramework.WardaSynthesizer.arm64/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.sharing.ShareSheetUI/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.BKAgentService/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.MobileSMS.spotlight/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.tonelibraryd/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.Maps/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.AMPDeviceDiscoveryAgent/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.systempreferences.AppleIDSettings/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.SafariPlatformSupport.Helper/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.microsoft.OneDriveLauncher/Data: Operation not permitted
find: /Users/alexa/Library/Containers/422E815A-C3C8-4F43-BAB9-D392BF34F5A0/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.Home: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.Safari: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.Safari.CacheDeleteExtension/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.lighthouse.SiriCoreMetricsWorker/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.wallpaper.extension.video/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.aiml.RepackagingWorker/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.AMPArtworkAgent/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.FollowUpSettings.FollowUpSettingsExtension/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.clock.WorldClockWidget/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.microsoft.Word/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.inputmethod.EmojiFunctionRowItem/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.news.widget/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.ScreenTimeWidgetApplication.ScreenTimeWidgetExtension/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.microsoft.OneDrive.FinderSync/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.AutoFillPanelService/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.speech.MacinTalkFramework.MacinTalkAUSP/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.QuickLookThumbnailing.extension.ThumbnailExtension-macOS/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.photoanalysisd/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.notificationcenterui/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.microsoft.OneDrive.FileProvider/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.CloudDocs.MobileDocumentsFileProvider: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.iCloudQuota.ICQFollowup/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.mail: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.MailShortcutsExtension/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.FamilyControlsAgent/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.siri.metrics.ExperimentationExtension/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.MobileSMS: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.SafariFoundation.CredentialProviderExtensionHelper/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.Music.MusicCacheExtension/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.calendar.CalendarFocusConfigurationExtension/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.LoginUserService/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish.mac-provider/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.AppStore/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.Siri/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.Notes: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.MailCacheDelete/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.mlhost.CloudWorker/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.siri.metrics.DevicePropertiesExtension/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.helpviewer/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.TextEdit/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.geod/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.news: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.TV.TVCacheExtension/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.iCloudDriveCore.telemetry-disk-checker/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.diskspaced/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.TestFlight.ServiceExtension/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.texttospeech.SiriAUSP/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.routined/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.microsoft.Excel/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.corerecents.recentsd/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.stocks.widget/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.Preview/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.UsageTrackingAgent/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.Passwords-Settings.extension/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.CoreRoutine.helperservice/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.siri.metrics.MetricsExtension/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.barebones.bbedit/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.stocks: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.Safari.SafariLinkExtension/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.quicklook.ui.helper/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.SiriNCService/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.ax.MauiTTSSupport.MauiAUSP/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.AirPlayUIAgent/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.voicebankingd/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.CloudDocs.iCloudDriveFileProvider/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish.NotificationService/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.mediaanalysisd/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.MobileSMS.MessagesActionExtension/Data: Operation not permitted
find: /Users/alexa/Library/Containers/com.apple.Family/Data: Operation not permitted
find: /Users/alexa/Library/ContainerManager: Operation not permitted
find: /Users/alexa/Library/PersonalizationPortrait: Operation not permitted
find: /Users/alexa/Library/Metadata/CoreSpotlight: Operation not permitted
find: /Users/alexa/Library/Cookies: Operation not permitted
find: /Users/alexa/Library/CoreFollowUp: Operation not permitted
find: /Users/alexa/Library/StatusKit: Operation not permitted
find: /Users/alexa/Library/DoNotDisturb: Operation not permitted
find: /Users/alexa/Library/Caches/com.apple.HomeKit: Operation not permitted
find: /Users/alexa/Library/Caches/CloudKit: Operation not permitted
find: /Users/alexa/Library/Caches/com.apple.Safari: Operation not permitted
find: /Users/alexa/Library/Caches/com.apple.findmy.fmfcore: Operation not permitted
find: /Users/alexa/Library/Caches/com.apple.containermanagerd: Operation not permitted
find: /Users/alexa/Library/Caches/FamilyCircle: Operation not permitted
find: /Users/alexa/Library/Caches/com.apple.homed: Operation not permitted
find: /Users/alexa/Library/Caches/com.apple.findmy.fmipcore: Operation not permitted
find: /Users/alexa/Library/Caches/com.apple.ap.adprivacyd: Operation not permitted
find: /Users/alexa/.Trash: Operation not permitted
  0B        /Users/alexa/.nvm/test/fast/Unit tests/mocks/project_dirs/inside-n_m-nested-pkg/node_modules
  0B        /Users/alexa/.nvm/test/fast/Unit tests/mocks/project_dirs/inside-n_m-nested/node_modules
  0B        /Users/alexa/.nvm/test/fast/Unit tests/mocks/project_dirs/nested-both/node_modules
  0B        /Users/alexa/.nvm/test/fast/Unit tests/mocks/project_dirs/nested-n_m/node_modules
  0B        /Users/alexa/.nvm/test/fast/Unit tests/mocks/project_dirs/no-nesting-both/node_modules
  0B        /Users/alexa/.nvm/test/fast/Unit tests/mocks/project_dirs/no-nesting-n_m/node_modules
  0B        /Users/alexa/Downloads/roadie-lightbeam-fixed-cleaned/node_modules
  0B        /Users/alexa/Library/Mobile Documents/com~apple~CloudDocs/roadie-lightbeam-fixed/node_modules
4.0K        /Users/alexa/.vscode/extensions/github.vscode-pull-request-github-0.120.2/node_modules
4.0K        /Users/alexa/.vscode/extensions/vitest.explorer-1.32.1/packages/extension/node_modules
4.0K        /Users/alexa/.vscode/extensions/vitest.explorer-1.32.1/packages/shared/node_modules
4.0K        /Users/alexa/.vscode/extensions/vitest.explorer-1.32.1/packages/worker-legacy/node_modules
4.0K        /Users/alexa/.vscode/extensions/vitest.explorer-1.32.1/packages/worker/node_modules
4.0K        /Users/alexa/Downloads/GitHub Desktop 2.app/Contents/Resources/app/node_modules
4.0K        /Users/alexa/Downloads/GitHub Desktop 3.app/Contents/Resources/app/node_modules
4.0K        /Users/alexa/Downloads/GitHub Desktop.app/Contents/Resources/app/node_modules
8.0K        /Users/alexa/.vscode/extensions/ms-azuretools.vscode-containers-2.3.0/dist/node_modules
8.0K        /Users/alexa/projects/blackroad-os-prism-console/.next/standalone/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/@tsconfig+node10@1.0.12/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/@tsconfig+node12@1.0.11/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/@tsconfig+node14@1.0.3/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/@tsconfig+node16@1.0.4/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/abbrev@3.0.1/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/async-retry@1.3.3/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/end-of-stream@1.4.5/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/is-extglob@2.1.1/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/merge-stream@2.0.0/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/merge2@1.4.1/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/ms@2.1.1/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/ms@2.1.2/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/ms@2.1.3/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/once@1.3.3/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/once@1.4.0/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/p-finally@2.0.1/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/path-match@1.2.4/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/require-from-string@2.0.2/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/run-parallel@1.2.0/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/shebang-command@2.0.0/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/stream-to-array@2.3.0/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/stream-to-promise@2.2.0/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/strip-final-newline@2.0.0/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/toidentifier@1.0.0/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/universalify@2.0.1/node_modules
 16K        /Users/alexa/Library/pnpm/global/5/.pnpm/wrappy@1.0.2/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+elysia@0.1.13/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+fastify@0.1.16/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+h3@0.1.22/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+nestjs@0.2.17/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/async-listen@1.2.0/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/balanced-match@1.0.2/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/bindings@1.5.0/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/brace-expansion@1.1.12/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/buffer-crc32@0.2.13/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/bytes@3.1.0/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/chownr@2.0.0/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/convert-hrtime@3.0.0/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/http-errors@1.4.0/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/inherits@2.0.4/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/is-buffer@2.0.5/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/is-glob@4.0.3/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/is-number@7.0.0/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/is-stream@2.0.1/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/isarray@0.0.1/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/mimic-fn@2.1.0/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/npm-run-path@4.0.1/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/onetime@5.1.2/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/parse-ms@2.1.0/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/path-key@3.1.1/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/pend@1.2.0/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/pretty-ms@7.0.1/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/resolve-from@5.0.0/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/shebang-regex@3.0.0/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/throttleit@2.1.0/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/time-span@4.0.0/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/uid-promise@1.0.0/node_modules
 20K        /Users/alexa/Library/pnpm/global/5/.pnpm/unpipe@1.0.0/node_modules
 20K        /Users/alexa/blackroad-os-core/apps/desktop/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/ansis@4.2.0/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/arg@4.1.0/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/arg@4.1.3/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/content-type@1.0.4/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/create-require@1.1.1/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/end-of-stream@1.1.0/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/etag@1.8.1/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/fill-range@7.1.1/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/fs-minipass@2.1.0/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/inherits@2.0.1/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/jsonfile@6.2.0/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/lru-cache@6.0.0/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/make-error@1.3.6/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/queue-microtask@1.2.3/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/setprototypeof@1.1.1/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/signal-exit@3.0.7/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/statuses@1.5.0/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/webidl-conversions@3.0.1/node_modules
 24K        /Users/alexa/Library/pnpm/global/5/.pnpm/yn@3.1.1/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+error-utils@2.0.3/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+gatsby-plugin-vercel-analytics@1.0.11/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+hydrogen@1.3.3/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/async-listen@3.0.0/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/async-listen@3.0.1/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/async-sema@3.1.1/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/concat-map@0.0.1/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/get-stream@5.2.0/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/get-stream@6.0.1/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/glob-parent@5.1.2/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/http-errors@1.7.3/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/is-node-process@1.2.0/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/mime-types@2.1.35/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/minizlib@2.1.2/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/mri@1.2.0/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/picocolors@1.0.0/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/tree-kill@1.2.2/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/which@2.0.2/node_modules
 28K        /Users/alexa/Library/pnpm/global/5/.pnpm/yauzl-clone@1.0.4/node_modules
 32K        /Users/alexa/Library/pnpm/global/5/.pnpm/@edge-runtime+ponyfill@2.4.2/node_modules
 32K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+detect-agent@1.0.0/node_modules
 32K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+hono@0.2.16/node_modules
 32K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+rust@1.0.4/node_modules
 32K        /Users/alexa/Library/pnpm/global/5/.pnpm/cookie-es@2.0.0/node_modules
 32K        /Users/alexa/Library/pnpm/global/5/.pnpm/resolve-pkg-maps@1.0.0/node_modules
 32K        /Users/alexa/Library/pnpm/global/5/.pnpm/to-regex-range@5.0.1/node_modules
 32K        /Users/alexa/Library/pnpm/global/5/.pnpm/v8-compile-cache-lib@3.0.1/node_modules
 32K        /Users/alexa/Library/pnpm/global/5/.pnpm/xdg-app-paths@5.1.0/node_modules
 32K        /Users/alexa/Library/pnpm/global/5/.pnpm/yallist@4.0.0/node_modules
 32K        /Users/alexa/blackroad-os-core/apps/web/node_modules
 36K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+express@0.1.19_typescript@5.9.3/node_modules
 36K        /Users/alexa/Library/pnpm/global/5/.pnpm/isexe@2.0.0/node_modules
 36K        /Users/alexa/Library/pnpm/global/5/.pnpm/path-to-regexp@1.9.0/node_modules
 36K        /Users/alexa/Library/pnpm/global/5/.pnpm/pump@3.0.3/node_modules
 36K        /Users/alexa/Library/pnpm/global/5/.pnpm/raw-body@2.4.1/node_modules
 36K        /Users/alexa/Library/pnpm/global/5/.pnpm/stat-mode@0.3.0/node_modules
 36K        /Users/alexa/Library/pnpm/global/5/.pnpm/yauzl-promise@2.1.3/node_modules
 36K        /Users/alexa/blackroad-os-core/packages/sdk-ts/node_modules
 40K        /Users/alexa/.vscode/extensions/ms-kubernetes-tools.vscode-kubernetes-tools-1.3.26/node_modules
 40K        /Users/alexa/Library/pnpm/global/5/.pnpm/@types+estree@1.0.8/node_modules
 40K        /Users/alexa/Library/pnpm/global/5/.pnpm/file-uri-to-path@1.0.0/node_modules
 40K        /Users/alexa/Library/pnpm/global/5/.pnpm/promisepipe@3.0.0/node_modules
 40K        /Users/alexa/Library/pnpm/global/5/.pnpm/retry@0.13.1/node_modules
 44K        /Users/alexa/Library/pnpm/global/5/.pnpm/@rolldown+pluginutils@1.0.0-beta.35/node_modules
 44K        /Users/alexa/Library/pnpm/global/5/.pnpm/@types+json-schema@7.0.15/node_modules
 44K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+static-config@3.1.2/node_modules
 44K        /Users/alexa/Library/pnpm/global/5/.pnpm/cross-spawn@7.0.6/node_modules
 44K        /Users/alexa/Library/pnpm/global/5/.pnpm/detect-libc@2.1.2/node_modules
 44K        /Users/alexa/Library/pnpm/global/5/.pnpm/fast-deep-equal@3.1.3/node_modules
 44K        /Users/alexa/Library/pnpm/global/5/.pnpm/minimatch@3.1.2/node_modules
 44K        /Users/alexa/Library/pnpm/global/5/.pnpm/os-paths@4.4.0/node_modules
 48K        /Users/alexa/Library/pnpm/global/5/.pnpm/fd-slicer@1.1.0/node_modules
 48K        /Users/alexa/Library/pnpm/global/5/.pnpm/punycode@2.3.1/node_modules
 52K        /Users/alexa/Library/pnpm/global/5/.pnpm/@oxc-project+types@0.82.3/node_modules
 52K        /Users/alexa/Library/pnpm/global/5/.pnpm/@tootallnate+once@2.0.0/node_modules
 52K        /Users/alexa/Library/pnpm/global/5/.pnpm/acorn-import-attributes@1.9.5_acorn@8.15.0/node_modules
 52K        /Users/alexa/Library/pnpm/global/5/.pnpm/agent-base@7.1.4/node_modules
 52K        /Users/alexa/Library/pnpm/global/5/.pnpm/depd@1.1.2/node_modules
 52K        /Users/alexa/Library/pnpm/global/5/.pnpm/events-intercept@2.0.0/node_modules
 52K        /Users/alexa/Library/pnpm/global/5/.pnpm/graceful-fs@4.2.11/node_modules
 52K        /Users/alexa/Library/pnpm/global/5/.pnpm/https-proxy-agent@7.0.6/node_modules
 52K        /Users/alexa/Library/pnpm/global/5/.pnpm/node-gyp-build@4.8.4/node_modules
 52K        /Users/alexa/Library/pnpm/global/5/.pnpm/nopt@8.1.0/node_modules
 52K        /Users/alexa/Library/pnpm/global/5/.pnpm/readdirp@4.1.2/node_modules
 56K        /Users/alexa/Library/pnpm/global/5/.pnpm/@oxc-project+types@0.99.0/node_modules
 56K        /Users/alexa/Library/pnpm/global/5/.pnpm/@rolldown+pluginutils@1.0.0-beta.52/node_modules
 56K        /Users/alexa/Library/pnpm/global/5/.pnpm/json-schema-traverse@1.0.0/node_modules
 56K        /Users/alexa/Library/pnpm/global/5/.pnpm/reusify@1.1.0/node_modules
 56K        /Users/alexa/Library/pnpm/global/5/.pnpm/tinyexec@0.3.2/node_modules
 56K        /Users/alexa/Library/pnpm/global/5/.pnpm/xdg-portable@7.3.0/node_modules
 60K        /Users/alexa/Library/pnpm/global/5/.pnpm/@isaacs+balanced-match@4.0.1/node_modules
 60K        /Users/alexa/Library/pnpm/global/5/.pnpm/@nodelib+fs.stat@2.0.5/node_modules
 60K        /Users/alexa/Library/pnpm/global/5/.pnpm/@rollup+pluginutils@5.3.0/node_modules
 60K        /Users/alexa/Library/pnpm/global/5/.pnpm/chownr@3.0.0/node_modules
 60K        /Users/alexa/Library/pnpm/global/5/.pnpm/debug@4.3.4/node_modules
 60K        /Users/alexa/Library/pnpm/global/5/.pnpm/debug@4.4.3/node_modules
 60K        /Users/alexa/Library/pnpm/global/5/.pnpm/micro@9.3.5-canary.3/node_modules
 60K        /Users/alexa/Library/pnpm/global/5/.pnpm/mkdirp@1.0.4/node_modules
 60K        /Users/alexa/Library/pnpm/global/5/.pnpm/safer-buffer@2.1.2/node_modules
 64K        /Users/alexa/Library/pnpm/global/5/.pnpm/micromatch@4.0.8/node_modules
 64K        /Users/alexa/Library/pnpm/global/5/.pnpm/minipass@3.3.6/node_modules
 68K        /Users/alexa/Library/pnpm/global/5/.pnpm/@edge-runtime+format@2.2.1/node_modules
 68K        /Users/alexa/Library/pnpm/global/5/.pnpm/braces@3.0.3/node_modules
 68K        /Users/alexa/Library/pnpm/global/5/.pnpm/human-signals@1.1.1/node_modules
 68K        /Users/alexa/Library/pnpm/global/5/.pnpm/path-to-regexp@8.3.0/node_modules
 72K        /Users/alexa/Library/pnpm/global/5/.pnpm/@jridgewell+resolve-uri@3.1.2/node_modules
 72K        /Users/alexa/Library/pnpm/global/5/.pnpm/acorn-walk@8.3.4/node_modules
 72K        /Users/alexa/Library/pnpm/global/5/.pnpm/whatwg-url@5.0.0/node_modules
 76K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+cervel@0.0.7_typescript@5.9.3/node_modules
 76K        /Users/alexa/Library/pnpm/global/5/.pnpm/execa@3.2.0/node_modules
 76K        /Users/alexa/Library/pnpm/global/5/.pnpm/human-signals@2.1.0/node_modules
 76K        /Users/alexa/Library/pnpm/global/5/.pnpm/yauzl@2.10.0/node_modules
 80K        /Users/alexa/Library/pnpm/global/5/.pnpm/execa@5.1.1/node_modules
 84K        /Users/alexa/Library/pnpm/global/5/.pnpm/@isaacs+brace-expansion@5.0.0/node_modules
 84K        /Users/alexa/Library/pnpm/global/5/.pnpm/code-block-writer@10.1.1/node_modules
 84K        /Users/alexa/Library/pnpm/global/5/.pnpm/minipass@5.0.0/node_modules
 88K        /Users/alexa/Library/pnpm/global/5/.pnpm/estree-walker@2.0.2/node_modules
 88K        /Users/alexa/Library/pnpm/global/5/.pnpm/fastq@1.19.1/node_modules
 88K        /Users/alexa/Library/pnpm/global/5/.pnpm/semver@6.3.1/node_modules
 92K        /Users/alexa/.npm/_npx/0ba4002b88dd17fc/node_modules
 96K        /Users/alexa/Library/pnpm/global/5/.pnpm/@edge-runtime+vm@3.2.0/node_modules
 96K        /Users/alexa/Library/pnpm/global/5/.pnpm/@nodelib+fs.scandir@2.1.5/node_modules
 96K        /Users/alexa/Library/pnpm/global/5/.pnpm/path-browserify@1.0.1/node_modules
104K        /Users/alexa/.vscode-server/extensions/github.copilot-chat-0.31.5/node_modules
104K        /Users/alexa/.vscode/extensions/github.copilot-chat-0.31.5/node_modules
104K        /Users/alexa/Library/pnpm/global/5/.pnpm/@nodelib+fs.walk@1.2.8/node_modules
104K        /Users/alexa/Library/pnpm/global/5/.pnpm/node_modules
108K        /Users/alexa/.vscode/extensions/github.copilot-chat-0.32.5/node_modules
108K        /Users/alexa/Library/pnpm/global/5/.pnpm/es-module-lexer@1.4.1/node_modules
108K        /Users/alexa/Library/pnpm/global/5/.pnpm/picomatch@4.0.3/node_modules
112K        /Users/alexa/.vscode/extensions/saoudrizwan.claude-dev-3.37.1/node_modules
112K        /Users/alexa/.vscode/extensions/saoudrizwan.claude-dev-3.38.1/node_modules
112K        /Users/alexa/Library/pnpm/global/5/.pnpm/picomatch@2.3.1/node_modules
112K        /Users/alexa/Library/pnpm/global/5/.pnpm/yallist@5.0.0/node_modules
116K        /Users/alexa/Library/pnpm/global/5/node_modules
120K        /Users/alexa/Library/pnpm/global/5/.pnpm/@fastify+busboy@2.1.1/node_modules
120K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+redwood@2.4.6/node_modules
124K        /Users/alexa/Library/pnpm/global/5/.pnpm/path-to-regexp@6.3.0/node_modules
128K        /Users/alexa/Library/pnpm/global/5/.pnpm/@isaacs+fs-minipass@4.0.1/node_modules
128K        /Users/alexa/Library/pnpm/global/5/.pnpm/@jridgewell+trace-mapping@0.3.9/node_modules
132K        /Users/alexa/Library/pnpm/global/5/.pnpm/@cspotcode+source-map-support@0.8.1/node_modules
132K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+gatsby-plugin-vercel-builder@2.0.113/node_modules
140K        /Users/alexa/Library/pnpm/global/5/.pnpm/esbuild@0.14.47/node_modules
144K        /Users/alexa/Library/pnpm/global/5/.pnpm/any-promise@1.3.0/node_modules
144K        /Users/alexa/Library/pnpm/global/5/.pnpm/fs-extra@11.1.0/node_modules
152K        /Users/alexa/Library/pnpm/global/5/.pnpm/esbuild@0.23.1/node_modules
152K        /Users/alexa/Library/pnpm/global/5/.pnpm/esbuild@0.27.0/node_modules
156K        /Users/alexa/Library/pnpm/global/5/.pnpm/@iarna+toml@2.2.5/node_modules
156K        /Users/alexa/Library/pnpm/global/5/.pnpm/cjs-module-lexer@1.2.3/node_modules
156K        /Users/alexa/Library/pnpm/global/5/.pnpm/minizlib@3.1.0/node_modules
164K        /Users/alexa/Library/pnpm/global/5/.pnpm/@jridgewell+sourcemap-codec@1.5.5/node_modules
164K        /Users/alexa/Library/pnpm/global/5/.pnpm/node-fetch@2.6.7/node_modules
164K        /Users/alexa/Library/pnpm/global/5/.pnpm/signal-exit@4.0.2/node_modules
168K        /Users/alexa/Library/pnpm/global/5/.pnpm/get-tsconfig@4.13.0/node_modules
172K        /Users/alexa/Library/pnpm/global/5/.pnpm/srvx@0.8.9/node_modules
176K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+remix-builder@5.5.6/node_modules
180K        /Users/alexa/Library/pnpm/global/5/.pnpm/fsevents@2.3.3/node_modules
180K        /Users/alexa/Library/pnpm/global/5/.pnpm/node-fetch@2.6.9/node_modules
180K        /Users/alexa/Library/pnpm/global/5/.pnpm/node-fetch@2.7.0/node_modules
192K        /Users/alexa/Library/pnpm/global/5/.pnpm/generic-pool@3.4.2/node_modules
196K        /Users/alexa/blackroad-os-operator/mcp/servers/blackroad-browser/node_modules
196K        /Users/alexa/sandbox/blackroad-os-operator/mcp/servers/blackroad-browser/node_modules
200K        /Users/alexa/Library/pnpm/global/5/.pnpm/edge-runtime@2.5.9/node_modules
200K        /Users/alexa/blackroad-os-operator/workers/browser/mcp-server/node_modules
208K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+python@6.1.2/node_modules
216K        /Users/alexa/Library/pnpm/global/5/.pnpm/mime-db@1.52.0/node_modules
216K        /Users/alexa/Library/pnpm/global/5/.pnpm/web-vitals@0.2.4/node_modules
240K        /Users/alexa/Library/pnpm/global/5/.pnpm/tar@6.2.1/node_modules
260K        /Users/alexa/Library/pnpm/global/5/.pnpm/fast-glob@3.3.3/node_modules
260K        /Users/alexa/Library/pnpm/global/5/.pnpm/semver@7.5.4/node_modules
268K        /Users/alexa/Library/pnpm/global/5/.pnpm/semver@7.7.3/node_modules
272K        /Users/alexa/Library/pnpm/global/5/.pnpm/tr46@0.0.3/node_modules
276K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+ruby@2.2.3/node_modules
300K        /Users/alexa/Library/pnpm/global/5/.pnpm/chokidar@4.0.0/node_modules
304K        /Users/alexa/Library/pnpm/global/5/.pnpm/@mapbox+node-pre-gyp@2.0.3/node_modules
304K        /Users/alexa/Library/pnpm/global/5/.pnpm/json-schema-to-ts@1.6.4/node_modules
308K        /Users/alexa/.vscode/extensions/ms-edgedevtools.vscode-edge-devtools-2.1.10/node_modules
316K        /Users/alexa/Library/pnpm/global/5/.pnpm/minipass@7.1.2/node_modules
364K        /Users/alexa/.vscode/extensions/harryhopkinson.vs-code-runner-2.2.5/node_modules
392K        /Users/alexa/Library/pnpm/global/5/.pnpm/diff@4.0.2/node_modules
396K        /Users/alexa/Library/pnpm/global/5/.pnpm/iconv-lite@0.4.24/node_modules
420K        /Users/alexa/Library/pnpm/global/5/.pnpm/consola@3.4.2/node_modules
424K        /Users/alexa/.vscode/extensions/mhutchie.git-graph-1.30.0/node_modules
452K        /Users/alexa/.vscode/extensions/tomoki1207.pdf-1.2.2/node_modules
460K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+nft@1.1.1/node_modules
480K        /Users/alexa/Library/pnpm/global/5/.pnpm/ts-toolbelt@6.15.5/node_modules
484K        /Users/alexa/Library/Caches/com.apple.python/Users/alexa/.nvm/versions/node/v20.19.5/lib/node_modules
488K        /Users/alexa/Library/Caches/com.apple.python/usr/local/lib/node_modules
504K        /Users/alexa/Library/pnpm/global/5/.pnpm/path-to-regexp@6.1.0/node_modules
508K        /Users/alexa/Library/pnpm/global/5/.pnpm/@sinclair+typebox@0.25.24/node_modules
552K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+blob@1.0.2/node_modules
556K        /Users/alexa/Library/pnpm/global/5/.pnpm/path-scurry@2.0.1/node_modules
560K        /Users/alexa/Library/pnpm/global/5/.pnpm/tsx@4.19.2/node_modules
568K        /Users/alexa/Library/pnpm/global/5/.pnpm/acorn@8.15.0/node_modules
572K        /Users/alexa/Library/pnpm/global/5/.pnpm/glob@13.0.0/node_modules
584K        /Users/alexa/Library/pnpm/global/5/.pnpm/minimatch@10.1.1/node_modules
584K        /Users/alexa/Library/pnpm/global/5/.pnpm/rolldown@1.0.0-beta.52/node_modules
584K        /Users/alexa/Library/pnpm/global/5/.pnpm/uri-js@4.4.1/node_modules
592K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+fun@1.2.0/node_modules
676K        /Users/alexa/.vscode-server/extensions/github.copilot-1.372.0/dist/node_modules
676K        /Users/alexa/.vscode/extensions/github.copilot-1.372.0/dist/node_modules
676K        /Users/alexa/.vscode/extensions/github.copilot-1.378.1798/dist/node_modules
676K        /Users/alexa/.vscode/extensions/github.copilot-1.388.0/dist/node_modules
744K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+next@4.15.8/node_modules
744K        /Users/alexa/Library/pnpm/global/5/.pnpm/zod@3.22.4/node_modules
800K        /Users/alexa/Library/pnpm/global/5/.pnpm/@edge-runtime+primitives@4.1.0/node_modules
852K        /Users/alexa/Library/pnpm/global/5/.pnpm/lru-cache@11.2.4/node_modules
864K        /Users/alexa/.npm/_npx/0989021c841cf7b6/node_modules
908K        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+go@3.2.4/node_modules
1.0M        /Users/alexa/Library/pnpm/global/5/.pnpm/@oxc-project+runtime@0.82.3/node_modules
1.0M        /Users/alexa/Library/pnpm/global/5/.pnpm/rolldown@1.0.0-beta.35/node_modules
1.1M        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+backends@0.0.17_typescript@5.9.3/node_modules
1.1M        /Users/alexa/Library/pnpm/global/5/.pnpm/ts-node@10.9.1_@types+node@16.18.11_typescript@4.9.5/node_modules
1.3M        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+static-build@2.8.14/node_modules
1.3M        /Users/alexa/Library/pnpm/global/5/.pnpm/jose@5.9.6/node_modules
1.4M        /Users/alexa/Library/pnpm/global/5/.pnpm/@edge-runtime+node-utils@2.3.0/node_modules
1.5M        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+build-utils@13.2.3/node_modules
1.5M        /Users/alexa/Library/pnpm/global/5/.pnpm/ts-morph@12.0.0/node_modules
1.5M        /Users/alexa/Library/pnpm/global/5/.pnpm/undici@5.28.4/node_modules
1.5M        /Users/alexa/Library/pnpm/global/5/.pnpm/undici@5.29.0/node_modules
1.7M        /Users/alexa/.npm/_npx/cc2145a2fe1558fa/node_modules
1.8M        /Users/alexa/Library/pnpm/global/5/.pnpm/tar@7.5.2/node_modules
2.0M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.2-darwin-arm64/components/WebTools/node_modules
2.0M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.7-darwin-arm64/components/WebTools/node_modules
2.1M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.2-darwin-arm64/components/VSDebugCore/platforms/darwin-arm64/node_modules
2.1M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.7-darwin-arm64/components/VSDebugCore/platforms/darwin-arm64/node_modules
2.1M        /Users/alexa/.vscode/extensions/oracle.oracle-java-24.1.2/node_modules
2.2M        /Users/alexa/Library/pnpm/global/5/.pnpm/ajv@8.6.3/node_modules
2.7M        /Users/alexa/Library/Caches/typescript/5.9/node_modules
2.7M        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+node@5.5.15/node_modules
3.0M        /Users/alexa/.vscode/extensions/swiftlang.swift-vscode-2.11.20250806/node_modules
3.1M        /Users/alexa/.npm/_npx/7b1d68f041a84c52/node_modules
3.5M        /Users/alexa/Library/pnpm/global/5/.pnpm/@types+node@16.18.11/node_modules
4.3M        /Users/alexa/.npm/_npx/b92ed0e02e7e7f2b/node_modules
4.4M        /Users/alexa/Library/pnpm/global/5/.pnpm/@vercel+introspection@0.0.7/node_modules
5.5M        /Users/alexa/.vscode/extensions/postman.postman-for-vscode-1.17.0/node_modules
5.5M        /Users/alexa/.vscode/extensions/postman.postman-for-vscode-1.18.0/node_modules
5.6M        /Users/alexa/.cache/node/corepack/v1/pnpm/8.15.4/dist/node_modules
5.6M        /Users/alexa/.cache/node/corepack/v1/pnpm/8.15.8/dist/node_modules
5.9M        /Users/alexa/Library/Caches/com.anthropic.claudefordesktop.ShipIt/update.Tbcbkcy/Claude.app/Contents/Resources/app.asar.unpacked/node_modules
6.7M        /Users/alexa/.vscode/extensions/esbenp.prettier-vscode-11.0.0/node_modules
6.8M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.2-darwin-arm64/components/vs-code-coverage/platforms/darwin-arm64/node_modules
6.8M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.7-darwin-arm64/components/vs-code-coverage/platforms/darwin-arm64/node_modules
7.1M        /Users/alexa/.vscode/extensions/ms-python.python-2025.18.0-darwin-arm64/out/client/node_modules
7.4M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.2-darwin-arm64/components/dotnet-project-system/node_modules
7.4M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.7-darwin-arm64/components/dotnet-project-system/node_modules
7.5M        /Users/alexa/blackbox-workspace-fix/codex-infinity/.npm/_npx/aab42732f01924e5/node_modules
7.5M        /Users/alexa/codex-infinity/.npm/_npx/aab42732f01924e5/node_modules
7.6M        /Users/alexa/.npm/_npx/1c3f0e186a7095e1/node_modules
7.9M        /Users/alexa/Library/pnpm/global/5/.pnpm/esbuild-darwin-arm64@0.14.47/node_modules
8.4M        /Users/alexa/.cache/node/corepack/v1/pnpm/9.12.0/dist/node_modules
8.6M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.2-darwin-arm64/components/dnpsv/platforms/darwin-arm64/node_modules
8.6M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.7-darwin-arm64/components/dnpsv/platforms/darwin-arm64/node_modules
8.7M        /Users/alexa/Library/pnpm/global/5/.pnpm/vercel@49.2.0_typescript@5.9.3/node_modules
8.9M        /Users/alexa/.vscode/extensions/github.copilot-chat-0.33.2/node_modules
9.1M        /Users/alexa/Library/pnpm/global/5/.pnpm/@esbuild+darwin-arm64@0.23.1/node_modules
9.3M        /Users/alexa/.vscode/extensions/platformio.platformio-ide-3.3.4-darwin-arm64/node_modules
9.4M        /Users/alexa/.vscode/extensions/ms-vscode.vscode-serial-monitor-0.13.1/dist/node_modules
9.8M        /Users/alexa/.cache/node/corepack/v1/pnpm/10.18.1/dist/node_modules
9.9M        /Users/alexa/Library/pnpm/global/5/.pnpm/@esbuild+darwin-arm64@0.27.0/node_modules
 10M        /Users/alexa/.cache/node/corepack/v1/pnpm/10.11.0/dist/node_modules
 11M        /Users/alexa/.vscode/extensions/wallabyjs.quokka-vscode-1.0.744/node_modules
 11M        /Users/alexa/.vscode/extensions/wallabyjs.quokka-vscode-1.0.746/node_modules
 11M        /Users/alexa/Library/pnpm/global/5/.pnpm/@ts-morph+common@0.11.1/node_modules
 12M        /Users/alexa/.vscode/extensions/keploy.keployio-2.1.7/node_modules
 12M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.2-darwin-arm64/components/VSUnitTesting/platforms/darwin-arm64/node_modules
 12M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.7-darwin-arm64/components/VSUnitTesting/platforms/darwin-arm64/node_modules
 13M        /Users/alexa/.npm/_npx/9833c18b2d85bc59/node_modules
 15M        /Users/alexa/.cache/codacy/runtimes/node-v22.2.0-darwin-arm64/lib/node_modules
 15M        /Users/alexa/Library/pnpm/global/5/.pnpm/@rolldown+binding-darwin-arm64@1.0.0-beta.35/node_modules
 15M        /Users/alexa/actions-runner/externals/node20/lib/node_modules
 15M        /Users/alexa/blackroad-os-operator/actions-runner/externals/node20/lib/node_modules
 15M        /Users/alexa/blackroad-sandbox/actions-runner/externals/node20/lib/node_modules
 15M        /Users/alexa/blackroad-sandbox/blackroad-sandbox/actions-runner/externals/node20/lib/node_modules
 15M        /Users/alexa/projects/BlackRoad-Operating-System/actions-runner/externals/node20/lib/node_modules
 15M        /Users/alexa/sandbox/blackroad-os-operator/actions-runner/externals/node20/lib/node_modules
 16M        /Users/alexa/.vscode/cli/servers/Stable-385651c938df8a906869babee516bffd0ddb9829/server/extensions/node_modules
 16M        /Users/alexa/Downloads/Visual Studio Code 10.app/Contents/Resources/app/extensions/node_modules
 16M        /Users/alexa/Downloads/Visual Studio Code 2.app/Contents/Resources/app/extensions/node_modules
 16M        /Users/alexa/Downloads/Visual Studio Code 3.app/Contents/Resources/app/extensions/node_modules
 16M        /Users/alexa/Downloads/Visual Studio Code 4.app/Contents/Resources/app/extensions/node_modules
 16M        /Users/alexa/Downloads/Visual Studio Code 5.app/Contents/Resources/app/extensions/node_modules
 16M        /Users/alexa/Downloads/Visual Studio Code 6.app/Contents/Resources/app/extensions/node_modules
 16M        /Users/alexa/Downloads/Visual Studio Code 7.app/Contents/Resources/app/extensions/node_modules
 16M        /Users/alexa/Downloads/Visual Studio Code 8.app/Contents/Resources/app/extensions/node_modules
 16M        /Users/alexa/Downloads/Visual Studio Code 9.app/Contents/Resources/app/extensions/node_modules
 16M        /Users/alexa/Downloads/Visual Studio Code.app/Contents/Resources/app/extensions/node_modules
 17M        /Users/alexa/.npm/_npx/9ed06546b0653f96/node_modules
 17M        /Users/alexa/Library/pnpm/global/5/.pnpm/@rolldown+binding-darwin-arm64@1.0.0-beta.52/node_modules
 18M        /Users/alexa/actions-runner/externals/node24/lib/node_modules
 18M        /Users/alexa/blackroad-os-operator/actions-runner/externals/node24/lib/node_modules
 18M        /Users/alexa/blackroad-sandbox/actions-runner/externals/node24/lib/node_modules
 18M        /Users/alexa/blackroad-sandbox/blackroad-sandbox/actions-runner/externals/node24/lib/node_modules
 18M        /Users/alexa/projects/BlackRoad-Operating-System/actions-runner/externals/node24/lib/node_modules
 18M        /Users/alexa/sandbox/blackroad-os-operator/actions-runner/externals/node24/lib/node_modules
 19M        /Users/alexa/.vscode/extensions/asf.apache-netbeans-java-27.0.1/node_modules
 20M        /Users/alexa/.cache/codacy/tools/eslint@8.57.0/node_modules
 23M        /Users/alexa/.npm/_npx/8480d3151d186fa6/node_modules
 23M        /Users/alexa/Library/pnpm/global/5/.pnpm/typescript@5.9.3/node_modules
 27M        /Users/alexa/.vscode/extensions/alexnesnes.teleplot-1.1.4/node_modules
 28M        /Users/alexa/.npm/_npx/1bf7c3c15bf47d04/node_modules
 29M        /Users/alexa/blackroad-cli/node_modules
 35M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.2-darwin-arm64/components/CPS/platforms/darwin-arm64/node_modules
 35M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.7-darwin-arm64/components/CPS/platforms/darwin-arm64/node_modules
 41M        /Users/alexa/.npm/_npx/eea2bd7412d4593b/node_modules
 41M        /Users/alexa/.vscode/extensions/42crunch.vscode-openapi-4.40.0/node_modules
 46M        /Users/alexa/.vscode/cli/servers/Stable-385651c938df8a906869babee516bffd0ddb9829/server/node_modules
 53M        /Users/alexa/projects/blackroad-os-prism-console/.next/standalone/projects/blackroad-os-prism-console/node_modules
 55M        /Users/alexa/.npm/_npx/334debcfbdc435a8/node_modules
 55M        /Users/alexa/.vscode/extensions/wallabyjs.quokka-vscode-1.0.744/dist/wallaby/node_modules
 55M        /Users/alexa/.vscode/extensions/wallabyjs.quokka-vscode-1.0.746/dist/wallaby/node_modules
 57M        /Users/alexa/blackroad-console/node_modules
 57M        /Users/alexa/blackroad-os-pack-education/node_modules
 64M        /Users/alexa/Library/pnpm/global/5/.pnpm/typescript@4.9.5/node_modules
 73M        /Users/alexa/.vscode/extensions/danielsanmedium.dscodegpt-3.14.191/standalone/node_modules
 73M        /Users/alexa/Downloads/Visual Studio Code 10.app/Contents/Resources/app/node_modules
 73M        /Users/alexa/Downloads/Visual Studio Code 8.app/Contents/Resources/app/node_modules
 73M        /Users/alexa/Downloads/Visual Studio Code 9.app/Contents/Resources/app/node_modules
 74M        /Users/alexa/Downloads/Visual Studio Code 2.app/Contents/Resources/app/node_modules
 74M        /Users/alexa/Downloads/Visual Studio Code 3.app/Contents/Resources/app/node_modules
 74M        /Users/alexa/Downloads/Visual Studio Code 4.app/Contents/Resources/app/node_modules
 74M        /Users/alexa/Downloads/Visual Studio Code 5.app/Contents/Resources/app/node_modules
 74M        /Users/alexa/Downloads/Visual Studio Code 6.app/Contents/Resources/app/node_modules
 74M        /Users/alexa/Downloads/Visual Studio Code 7.app/Contents/Resources/app/node_modules
 74M        /Users/alexa/Downloads/Visual Studio Code.app/Contents/Resources/app/node_modules
 75M        /Users/alexa/.vscode/extensions/danielsanmedium.dscodegpt-3.14.172/standalone/node_modules
 77M        /Users/alexa/blackroad-os-operator/sdks/typescript/node_modules
 83M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.2-darwin-arm64/components/vs-green-server/platforms/darwin-arm64/node_modules
 83M        /Users/alexa/.vscode/extensions/ms-dotnettools.csdevkit-1.80.7-darwin-arm64/components/vs-green-server/platforms/darwin-arm64/node_modules
 96M        /Users/alexa/sandbox/blackroad-os-operator/sdks/typescript/node_modules
 99M        /Users/alexa/sandbox/blackroad-os-operator/workers/api-gateway/node_modules
101M        /Users/alexa/projects/blackroad-os-api/node_modules
128M        /Users/alexa/blackroad-prism-console/services/roadchain/node_modules
131M        /Users/alexa/Library/Application Support/Code/User/globalStorage/ms-edgedevtools.vscode-edge-devtools/node_modules
133M        /Users/alexa/blackroad-os-operator/workers/billing/node_modules
133M        /Users/alexa/blackroad-os-operator/workers/router/node_modules
142M        /Users/alexa/blackroad-os-operator/workers/logs/node_modules
146M        /Users/alexa/blackroad-os-operator/node_modules
149M        /Users/alexa/blackroad-os-agents/node_modules
155M        /Users/alexa/.npm/_npx/69f9afb961c37556/node_modules
160M        /Users/alexa/.npm/_npx/d77349f55c2be1c0/node_modules
165M        /Users/alexa/blackroad-landing-worker/node_modules
165M        /Users/alexa/blackroad-os-operator/workers/cece/node_modules
165M        /Users/alexa/blackroad-os-operator/workers/cloudflare-dns/node_modules
165M        /Users/alexa/blackroad-os-operator/workers/digitalocean-manager/node_modules
165M        /Users/alexa/blackroad-router/node_modules
165M        /Users/alexa/sandbox/blackroad-os-operator/node_modules
167M        /Users/alexa/blackroad-agent/node_modules
167M        /Users/alexa/blackroad-api/node_modules
167M        /Users/alexa/blackroad-helper/node_modules
167M        /Users/alexa/blackroad-mesh/node_modules
181M        /Users/alexa/Library/Containers/com.docker.docker/Data/extensions/ajeetraina_selenium-docker-extension/ui/ui/node_modules
181M        /Users/alexa/late-wood-832f/node_modules
183M        /Users/alexa/blackroad-sandbox/proud-cake-3a70/node_modules
183M        /Users/alexa/blackroad-sandbox/proud-cake-3a70/patient-sun-0807/node_modules
185M        /Users/alexa/Downloads/bost/node_modules
185M        /Users/alexa/Downloads/cat/node_modules
185M        /Users/alexa/Downloads/cat_final/node_modules
185M        /Users/alexa/Downloads/cat_fixed/node_modules
187M        /Users/alexa/blackroad-sandbox/blackroad-sandbox/node_modules
189M        /Users/alexa/blackroad-os-operator/workers/api-gateway/node_modules
189M        /Users/alexa/blackroad-os-operator/workers/auth/node_modules
196M        /Users/alexa/projects/blackroad-os-core/node_modules
250M        /Users/alexa/services/api/node_modules
250M        /Users/alexa/services/brand/node_modules
250M        /Users/alexa/services/docs/node_modules
250M        /Users/alexa/services/operator/node_modules
250M        /Users/alexa/services/prism/node_modules
250M        /Users/alexa/services/web/node_modules
256M        /Users/alexa/sandbox/blackroad-os-operator/workers/cece/node_modules
256M        /Users/alexa/sandbox/blackroad-os-operator/workers/cloudflare-dns/node_modules
347M        /Users/alexa/lucidia-platform/web/node_modules
360M        /Users/alexa/Library/Containers/com.docker.docker/Data/extensions/ajeetraina_neo4j-docker-extension/ui/ui/node_modules
442M        /Users/alexa/Downloads/node_modules
447M        /Users/alexa/projects/blackroad-os-prism-console/node_modules
496M        /Users/alexa/cloudflare-hello-world/blackroad-login/node_modules
552M        /Users/alexa/blackroad-os-web/node_modules
559M        /Users/alexa/.nvm/versions/node/v20.19.5/lib/node_modules
559M        /Users/alexa/lucidia-app/node_modules
600M        /Users/alexa/Downloads/roadie-react/node_modules
628M        /Users/alexa/blackroad-prism-console/apps/portals/node_modules
652M        /Users/alexa/Downloads/roadie-lightbeam-fixed/node_modules
664M        /Users/alexa/Downloads/roadie-react-final/node_modules
664M        /Users/alexa/Downloads/roadie-react-fixed/node_modules
667M        /Users/alexa/Downloads/roadie-lightbeam-final-clean/node_modules
704M        /Users/alexa/Downloads/roadie-react-complete/node_modules
707M        /Users/alexa/blackroad-os-core/node_modules
1.2G        /Users/alexa/node_modules
alexa@Alexas-MacBook-Pro-2 blackroad-sandbox % rm -rf path/to/node_modules
alexa@Alexas-MacBook-Pro-2 blackroad-sandbox % pip cache purge
Files removed: 269 (24.9 MB)
alexa@Alexas-MacBook-Pro-2 blackroad-sandbox % rm -rf ~/.cache/*
zsh: sure you want to delete all 7 files in /Users/alexa/.cache [yn]? y
n
alexa@Alexas-MacBook-Pro-2 blackroad-sandbox % n
zsh: command not found: n
alexa@Alexas-MacBook-Pro-2 blackroad-sandbox % rm -rf ~/Library/Caches/*
zsh: sure you want to delete more than 100 files in /Users/alexa/Library/Caches [yn]? y
n
rm: /Users/alexa/Library/Caches/CloudKit: Operation not permitted
rm: /Users/alexa/Library/Caches/FamilyCircle: Operation not permitted
rm: /Users/alexa/Library/Caches/com.apple.HomeKit: Operation not permitted
rm: /Users/alexa/Library/Caches/com.apple.Safari: Operation not permitted
rm: /Users/alexa/Library/Caches/com.apple.ap.adprivacyd: Operation not permitted
rm: /Users/alexa/Library/Caches/com.apple.containermanagerd: Operation not permitted
rm: /Users/alexa/Library/Caches/com.apple.findmy.fmfcore: Operation not permitted
rm: /Users/alexa/Library/Caches/com.apple.findmy.fmipcore: Operation not permitted
rm: /Users/alexa/Library/Caches/com.apple.homed: Operation not permitted
alexa@Alexas-MacBook-Pro-2 blackroad-sandbox % n
zsh: command not found: n
alexa@Alexas-MacBook-Pro-2 blackroad-sandbox % du -h -d 1 ~ | sort -h
du: /Users/alexa/Library/Application Support/CallHistoryTransactions: Operation not permitted
du: /Users/alexa/Library/Application Support/CloudDocs/session/db: Operation not permitted
du: /Users/alexa/Library/Application Support/com.apple.sharedfilelist: Operation not permitted
du: /Users/alexa/Library/Application Support/Knowledge: Operation not permitted
du: /Users/alexa/Library/Application Support/com.apple.TCC: Operation not permitted
du: /Users/alexa/Library/Application Support/FileProvider: Operation not permitted
du: /Users/alexa/Library/Application Support/FaceTime: Operation not permitted
du: /Users/alexa/Library/Application Support/com.apple.avfoundation/Frecents: Operation not permitted
du: /Users/alexa/Library/Application Support/CallHistoryDB: Operation not permitted
du: /Users/alexa/Library/Assistant/SiriVocabulary: Operation not permitted
du: /Users/alexa/Library/Daemon Containers: Operation not permitted
du: /Users/alexa/Library/Autosave Information: Operation not permitted
du: /Users/alexa/Library/IdentityServices: Operation not permitted
du: /Users/alexa/Library/Calendars: Operation not permitted
du: /Users/alexa/Library/Messages: Operation not permitted
du: /Users/alexa/Library/HomeKit: Operation not permitted
du: /Users/alexa/Library/Sharing: Operation not permitted
du: /Users/alexa/Library/com.apple.aiml.instrumentation: Operation not permitted
du: /Users/alexa/Library/Mail: Operation not permitted
du: /Users/alexa/Library/Trial: Operation not permitted
du: /Users/alexa/Library/AppleMediaServices: Operation not permitted
du: /Users/alexa/Library/DuetExpertCenter: Operation not permitted
du: /Users/alexa/Library/Accounts: Operation not permitted
du: /Users/alexa/Library/Safari: Operation not permitted
du: /Users/alexa/Library/Biome: Operation not permitted
du: /Users/alexa/Library/IntelligencePlatform: Operation not permitted
du: /Users/alexa/Library/Shortcuts: Operation not permitted
du: /Users/alexa/Library/Suggestions: Operation not permitted
du: /Users/alexa/Library/Weather: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.accessibility.voicebanking: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.stocks: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.VoiceMemos.shared: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.secure-control-center-preferences: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.chronod: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.private.translation: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.calendar: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.testflight: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.newsd: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.siri.userfeedbacklearning: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.gamecenter: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.tips: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.spotlight: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.sharingd: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.weather: Operation not permitted
du: /Users/alexa/Library/Group Containers/com.apple.systempreferences.cache: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.feedbacklogger: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.notes: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.tipsnext: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.Safari.SandboxBroker: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.transparency: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.reminders: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.mail: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.DeviceActivity: Operation not permitted
du: /Users/alexa/Library/Group Containers/com.apple.Home.group: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.iCloudDrive: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.Photos.PhotosFileProvider: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.AppleSpell: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.mlhost: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.PegasusConfiguration: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.CloudPhotosConfiguration/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.PressAndHold/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.siri.SiriPrivateLearningAnalytics.SiriUserSegmentation/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.VoiceMemos: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.mlhost.TelemetryWorker/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.ax.KonaTTSSupport.KonaSynthesizer/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.CoreDevice.remotepairingd/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Notes.LPPreviewGenerator/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish.upload/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.archiveutility: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.ScreenTimeAgent/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.LighthouseBitacoraFramework.BitacoraWorker/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.speech.MacinTalkFramework.WardaSynthesizer.x86-64/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.weather.widget/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.photos.ImageConversionService/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Photos.PhotosFileProvider/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.quicklook.QuickLookUIService/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.iCal.CalendarWidgetExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.contacts.donation-agent/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.photolibraryd/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.siri.media-indexer/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.speech.MacinTalkFramework.WardaSynthesizer.arm64/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.sharing.ShareSheetUI/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.BKAgentService/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.MobileSMS.spotlight/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.tonelibraryd/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Maps/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.AMPDeviceDiscoveryAgent/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.systempreferences.AppleIDSettings/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.SafariPlatformSupport.Helper/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.microsoft.OneDriveLauncher/Data: Operation not permitted
du: /Users/alexa/Library/Containers/422E815A-C3C8-4F43-BAB9-D392BF34F5A0/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Home: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Safari: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Safari.CacheDeleteExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.lighthouse.SiriCoreMetricsWorker/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.wallpaper.extension.video/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.aiml.RepackagingWorker/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.AMPArtworkAgent/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.FollowUpSettings.FollowUpSettingsExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.clock.WorldClockWidget/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.microsoft.Word/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.inputmethod.EmojiFunctionRowItem/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.news.widget/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.ScreenTimeWidgetApplication.ScreenTimeWidgetExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.microsoft.OneDrive.FinderSync/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.AutoFillPanelService/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.speech.MacinTalkFramework.MacinTalkAUSP/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.QuickLookThumbnailing.extension.ThumbnailExtension-macOS/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.photoanalysisd/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.notificationcenterui/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.microsoft.OneDrive.FileProvider/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.CloudDocs.MobileDocumentsFileProvider: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.iCloudQuota.ICQFollowup/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.mail: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.MailShortcutsExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.FamilyControlsAgent/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.siri.metrics.ExperimentationExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.MobileSMS: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.SafariFoundation.CredentialProviderExtensionHelper/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Music.MusicCacheExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.calendar.CalendarFocusConfigurationExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.LoginUserService/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish.mac-provider/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.AppStore/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Siri/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Notes: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.MailCacheDelete/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.mlhost.CloudWorker/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.siri.metrics.DevicePropertiesExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.helpviewer/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.TextEdit/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.geod/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.news: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.TV.TVCacheExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.iCloudDriveCore.telemetry-disk-checker/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.diskspaced/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.TestFlight.ServiceExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.texttospeech.SiriAUSP/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.routined/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.microsoft.Excel/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.corerecents.recentsd/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.stocks.widget/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Preview/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.UsageTrackingAgent/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Passwords-Settings.extension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.CoreRoutine.helperservice/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.siri.metrics.MetricsExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.barebones.bbedit/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.stocks: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Safari.SafariLinkExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.quicklook.ui.helper/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.SiriNCService/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.ax.MauiTTSSupport.MauiAUSP/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.AirPlayUIAgent/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.voicebankingd/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.CloudDocs.iCloudDriveFileProvider/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish.NotificationService/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.mediaanalysisd/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.MobileSMS.MessagesActionExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Family/Data: Operation not permitted
du: /Users/alexa/Library/ContainerManager: Operation not permitted
du: /Users/alexa/Library/PersonalizationPortrait: Operation not permitted
du: /Users/alexa/Library/Metadata/CoreSpotlight: Operation not permitted
du: /Users/alexa/Library/Cookies: Operation not permitted
du: /Users/alexa/Library/CoreFollowUp: Operation not permitted
du: /Users/alexa/Library/StatusKit: Operation not permitted
du: /Users/alexa/Library/DoNotDisturb: Operation not permitted
du: /Users/alexa/Library/Caches/com.apple.HomeKit: Operation not permitted
du: /Users/alexa/Library/Caches/CloudKit: Operation not permitted
du: /Users/alexa/Library/Caches/com.apple.Safari: Operation not permitted
du: /Users/alexa/Library/Caches/com.apple.findmy.fmfcore: Operation not permitted
du: /Users/alexa/Library/Caches/com.apple.containermanagerd: Operation not permitted
du: /Users/alexa/Library/Caches/FamilyCircle: Operation not permitted
du: /Users/alexa/Library/Caches/com.apple.homed: Operation not permitted
du: /Users/alexa/Library/Caches/com.apple.findmy.fmipcore: Operation not permitted
du: /Users/alexa/Library/Caches/com.apple.ap.adprivacyd: Operation not permitted
du: /Users/alexa/.Trash: Operation not permitted
  0B        /Users/alexa/...
  0B        /Users/alexa/.cache
  0B        /Users/alexa/.plastic4
  0B        /Users/alexa/.remoteit
  0B        /Users/alexa/.wallaby
  0B        /Users/alexa/Public
  0B        /Users/alexa/[-m
  0B        /Users/alexa/[-pv]
  0B        /Users/alexa/code
  0B        /Users/alexa/cosmic_rave_auto
  0B        /Users/alexa/directory_name
  0B        /Users/alexa/jetson-mount
  0B        /Users/alexa/mode]
4.0K        /Users/alexa/.aspnet
4.0K        /Users/alexa/.bitowingman
4.0K        /Users/alexa/.br-windows
4.0K        /Users/alexa/.cups
4.0K        /Users/alexa/.dartServer
4.0K        /Users/alexa/.doppler
4.0K        /Users/alexa/.fitten
4.0K        /Users/alexa/.idlerc
4.0K        /Users/alexa/.minikube
4.0K        /Users/alexa/.odo
4.0K        /Users/alexa/.pnpm-state
4.0K        /Users/alexa/.redhat
4.0K        /Users/alexa/.warp
4.0K        /Users/alexa/lucidia-model
8.0K        /Users/alexa/.android
8.0K        /Users/alexa/.streamlit
 12K        /Users/alexa/infra
 16K        /Users/alexa/.dart-tool
 16K        /Users/alexa/blackroad-subdomains
 16K        /Users/alexa/blackroad_app
 16K        /Users/alexa/lucidia_app
 20K        /Users/alexa/.railway
 20K        /Users/alexa/blackroad-landing
 24K        /Users/alexa/.lucidia
 24K        /Users/alexa/blackroad-scripts
 24K        /Users/alexa/blackroad-sdk
 28K        /Users/alexa/.cloudflared
 28K        /Users/alexa/.config
 36K        /Users/alexa/.bito
 60K        /Users/alexa/blackroad-workflows
 60K        /Users/alexa/templates
 80K        /Users/alexa/.gnupg
 88K        /Users/alexa/.qodo
112K        /Users/alexa/.ssh
124K        /Users/alexa/.matplotlib
124K        /Users/alexa/blackroad-domains
128K        /Users/alexa/blackroad-protocol
132K        /Users/alexa/lucidia-lab
136K        /Users/alexa/blackroad-brand
144K        /Users/alexa/blackroad-home
148K        /Users/alexa/blackroad-demo
152K        /Users/alexa/universal-computer
164K        /Users/alexa/blackroad-docs
164K        /Users/alexa/remember
172K        /Users/alexa/.semgrep
172K        /Users/alexa/new_world
172K        /Users/alexa/quantum-math-lab
188K        /Users/alexa/native-ai-quantum-energy
204K        /Users/alexa/Movies
288K        /Users/alexa/blackroad
640K        /Users/alexa/.kube
676K        /Users/alexa/.templateengine
708K        /Users/alexa/blackroad-pi-holo
768K        /Users/alexa/blackroad-pi-ops
836K        /Users/alexa/BlackRoad.io
912K        /Users/alexa/lucidia-math
932K        /Users/alexa/blackroad-os-master
952K        /Users/alexa/blackroad-os-pack-infra-devops
976K        /Users/alexa/.codex
984K        /Users/alexa/blackroad-os-pack-legal
1.0M        /Users/alexa/blackroad-os-pack-research-lab
1.1M        /Users/alexa/blackroad-agents
1.1M        /Users/alexa/blackroad-os-research
1.2M        /Users/alexa/blackroad-os-ideas
1.3M        /Users/alexa/blackroad-os-beacon
1.3M        /Users/alexa/blackroad-os-demo
1.3M        /Users/alexa/blackroad-os-pack-creator-studio
1.3M        /Users/alexa/blackroad-os-pack-finance
1.4M        /Users/alexa/blackroad-os-archive
1.4M        /Users/alexa/monaco-editor-samples
1.5M        /Users/alexa/blackroad-os-api-gateway
1.6M        /Users/alexa/blackroad-os-brand
1.6M        /Users/alexa/blackroad-os-home
1.8M        /Users/alexa/blackroad-os-api
1.8M        /Users/alexa/lucidia-core
2.0M        /Users/alexa/blackroad-os-prism-console
2.1M        /Users/alexa/.codegpt
2.1M        /Users/alexa/.quokka
2.4M        /Users/alexa/blackroad-tools
2.5M        /Users/alexa/.dotnet
2.9M        /Users/alexa/blackroad-os-infra
3.0M        /Users/alexa/.composer
3.0M        /Users/alexa/blackroad-os
3.9M        /Users/alexa/blackroad-os-docs
6.0M        /Users/alexa/.ServiceHub
6.3M        /Users/alexa/.degit
 11M        /Users/alexa/blackroad-backup
 12M        /Users/alexa/lucidia
 12M        /Users/alexa/lucidia‑venv
 14M        /Users/alexa/.wrangler
 14M        /Users/alexa/Applications
 14M        /Users/alexa/BlackRoad-Operating-System
 15M        /Users/alexa/untitled folder
 17M        /Users/alexa/Music
 23M        /Users/alexa/codex-infinity
 36M        /Users/alexa/nltk_data
 37M        /Users/alexa/blackroad-cli
 43M        /Users/alexa/.zsh_sessions
 58M        /Users/alexa/blackroad-os-pack-education
110M        /Users/alexa/blackroad-agent-os
119M        /Users/alexa/bin
121M        /Users/alexa/PycharmProjects
133M        /Users/alexa/.vscode-server
149M        /Users/alexa/blackroad-workspace-fix
153M        /Users/alexa/blackroad-recovery-20251202-093052
165M        /Users/alexa/blackroad-landing-worker
165M        /Users/alexa/blackroad-router
167M        /Users/alexa/blackroad-agent
168M        /Users/alexa/blackroad-helper
168M        /Users/alexa/blackroad-mesh
175M        /Users/alexa/.platformio
188M        /Users/alexa/.vs-kubernetes
201M        /Users/alexa/lucidia-env
229M        /Users/alexa/blackroad-api
245M        /Users/alexa/late-wood-832f
265M        /Users/alexa/blackroad-os-agents
361M        /Users/alexa/.claude
364M        /Users/alexa/go
368M        /Users/alexa/Documents
401M        /Users/alexa/.nuget
401M        /Users/alexa/lucidia-platform
429M        /Users/alexa/Pictures
473M        /Users/alexa/.cargo
511M        /Users/alexa/cloudflare-hello-world
553M        /Users/alexa/actions-runner
580M        /Users/alexa/.local
631M        /Users/alexa/lucidia-app
693M        /Users/alexa/blackbox-workspace-fix
711M        /Users/alexa/blackroad-os-core
716M        /Users/alexa/blackroad-os-web
721M        /Users/alexa/.nvm
808M        /Users/alexa/SenseCAP-Watcher-Firmware
1.2G        /Users/alexa/.rustup
1.2G        /Users/alexa/node_modules
1.4G        /Users/alexa/blackroad-prism-console
1.5G        /Users/alexa/projects
1.5G        /Users/alexa/services
1.7G        /Users/alexa/sandbox
1.9G        /Users/alexa/OpenWorldPrototype
2.0G        /Users/alexa/My project
2.6G        /Users/alexa/blackroad-os-operator
2.7G        /Users/alexa/esp-idf
3.0G        /Users/alexa/blackroad-console
3.3G        /Users/alexa/.espressif
3.6G        /Users/alexa/Chit Chat Cadillac
4.0G        /Users/alexa/.blackroad
4.4G        /Users/alexa/Desktop
5.8G        /Users/alexa/blackroad-sandbox
5.9G        /Users/alexa/.npm
6.1G        /Users/alexa/.vscode
 14G        /Users/alexa/.docker
 27G        /Users/alexa/.ollama
 49G        /Users/alexa/Library
 96G        /Users/alexa/Downloads
251G        /Users/alexa
alexa@Alexas-MacBook-Pro-2 blackroad-sandbox % sudo du -h -d 1 / | sort -h
Password:
du: /Library/Application Support/com.apple.TCC: Operation not permitted
du: /Library/Trial: Operation not permitted
du: /Library/Caches/com.apple.amsengagementd.classicdatavault: Operation not permitted
du: /Library/Caches/com.apple.aneuserd: Operation not permitted
du: /Library/Caches/com.apple.aned: Operation not permitted
du: /System/Volumes/Update/.TemporaryItems: Operation not permitted
du: /System/Volumes/Preboot/.TemporaryItems: Operation not permitted
du: /System/Volumes/Preboot/com.apple.security.cryptexd: Operation not permitted
du: /System/Volumes/Data/home: Operation not permitted
du: /System/Volumes/Data/.Spotlight-V100: Operation not permitted
du: /System/Volumes/Data/Library/Application Support/com.apple.TCC: Operation not permitted
du: /System/Volumes/Data/Library/Trial: Operation not permitted
du: /System/Volumes/Data/Library/Caches/com.apple.amsengagementd.classicdatavault: Operation not permitted
du: /System/Volumes/Data/Library/Caches/com.apple.aneuserd: Operation not permitted
du: /System/Volumes/Data/Library/Caches/com.apple.aned: Operation not permitted
du: /System/Volumes/Data/private/var/networkd/db: Operation not permitted
du: /System/Volumes/Data/private/var/OOPJit: Operation not permitted
du: /System/Volumes/Data/private/var/db/appinstalld: Operation not permitted
du: /System/Volumes/Data/private/var/db/ExtensibleSSO/Configuration: Operation not permitted
du: /System/Volumes/Data/private/var/db/os_eligibility: Operation not permitted
du: /System/Volumes/Data/private/var/db/Spotlight: Operation not permitted
du: /System/Volumes/Data/private/var/db/sysdiagnose/com.apple.sysdiagnose: Operation not permitted
du: /System/Volumes/Data/private/var/db/SoC: Operation not permitted
du: /System/Volumes/Data/private/var/db/DumpPanic: Operation not permitted
du: /System/Volumes/Data/private/var/db/rmd/secure: Operation not permitted
du: /System/Volumes/Data/private/var/db/com.apple.backgroundtaskmanagement: Operation not permitted
du: /System/Volumes/Data/private/var/db/fpsd/dvp: Operation not permitted
du: /System/Volumes/Data/private/var/db/installcoordinationd: Operation not permitted
du: /System/Volumes/Data/private/var/db/Spotlight-V100: Operation not permitted
du: /System/Volumes/Data/private/var/db/oah: Operation not permitted
du: /System/Volumes/Data/private/var/db/Sandbox: Operation not permitted
du: /System/Volumes/Data/private/var/db/lockdown: Operation not permitted
du: /System/Volumes/Data/private/var/db/biome: Operation not permitted
du: /System/Volumes/Data/private/var/db/KernelExtensionManagement/Staging: Operation not permitted
du: /System/Volumes/Data/private/var/db/DifferentialPrivacy: Operation not permitted
du: /System/Volumes/Data/private/var/db/MobileIdentityService: Operation not permitted
du: /System/Volumes/Data/private/var/db/searchparty: Operation not permitted
du: /System/Volumes/Data/private/var/db/CoreDuet: Operation not permitted
du: /System/Volumes/Data/private/var/db/ConfigurationProfiles/Store: Operation not permitted
du: /System/Volumes/Data/private/var/folders/vn/j61v2nrj3tbf4c79n5r1cqbc0000gp/0/com.apple.LaunchServices.dv: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.ScreenTimeAgent/Store: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.lockoutagent: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.progressd/ClassKit: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.exchangesync: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.LaunchServices.dv: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/dmd: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.nsurlsessiond: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.SharedWebCredentials: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.FeatureStore: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.routined/dv: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.appleaccountd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.syncdefaultsd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.transparencyd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.siriactionsd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.triald/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.ap.promotedcontentd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.appstoreagent/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.imtransferservices.IMTransferAgent/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.icloud.searchpartyd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.parsec-fbf/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.useractivityd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/gamed/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.fileproviderd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.nsurlsessiond/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.imtranscoding.IMTranscoderAgent/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.passd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.chrono/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.calaccessd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.remindd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.studentd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.parsecd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.identityservicesd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.sharingd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.shazamd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.bird/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.storekit/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.appstorecomponentsd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/homed/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.quicklook.ThumbnailsAgent/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.pluginkit/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.maps.destinationd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.AUHelperService/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.donotdisturbd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.imagent/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.weatherd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.imdpersistence.IMDPersistenceAgent/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.amsengagementd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/C/com.apple.siriactionsd/ShortcutsSandboxCache: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/C/com.apple.WebKit.WebContent.Sandbox: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/C/com.apple.WebKit.Networking.Sandbox: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/C/com.apple.quicklook.ThumbnailsAgent/com.apple.QuickLook.thumbnailcache: Operation not permitted
du: /System/Volumes/Data/private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/C/com.apple.WebKit.GPU.Sandbox: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000sm00006d/0: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000sm00006d/C: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n000012800008k/T/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n000013800008t/T/com.apple.trustd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000y800007k/0/com.apple.nsurlsessiond: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000y800007k/T/com.apple.nsurlsessiond/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/com.apple.ScreenTimeAgent/Store: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/com.apple.lockoutagent: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/com.apple.progressd/ClassKit: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/com.apple.exchangesync: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/dmd: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/com.apple.nsurlsessiond: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/com.apple.SharedWebCredentials: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/com.apple.routined/dv: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/C/com.apple.quicklook.ThumbnailsAgent/com.apple.QuickLook.thumbnailcache: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000s0000068/T/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000s0000068/C/com.apple.WebKit.WebContent.Sandbox: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000s0000068/C/com.apple.WebKit.Networking.Sandbox: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n00000s0000068/C/com.apple.WebKit.GPU.Sandbox: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n000012r00008p/T/com.apple.MobileAccessoryUpdater/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n000012400008j/T/com.apple.appinstalld/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/0/com.apple.LaunchServices.dv: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.mobileassetd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.dasd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.revisiond/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/countryd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.icloud.searchpartyd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.aned/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.nehelper/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.AppStoreDaemon.StorePrivilegedODRService/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.GSSCred/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.kernelmanagerd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.wifianalyticsd/TemporaryItems: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/C/com.apple.WebKit.WebContent.Sandbox: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/C/com.apple.WebKit.Networking.Sandbox: Operation not permitted
du: /System/Volumes/Data/private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/C/com.apple.WebKit.GPU.Sandbox: Operation not permitted
du: /System/Volumes/Data/private/var/protected/trustd/private: Operation not permitted
du: /System/Volumes/Data/.DocumentRevisions-V100: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Application Support/CallHistoryTransactions: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Application Support/CloudDocs/session/db: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Application Support/com.apple.sharedfilelist: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Application Support/Knowledge: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Application Support/com.apple.TCC: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Application Support/FileProvider: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Application Support/FaceTime: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Application Support/com.apple.avfoundation/Frecents: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Application Support/CallHistoryDB: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Assistant/SiriVocabulary: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Daemon Containers: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Autosave Information: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/IdentityServices: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Calendars: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Messages: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/HomeKit: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Sharing: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/com.apple.aiml.instrumentation: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Mail: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Trial: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/AppleMediaServices: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/DuetExpertCenter: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Accounts: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Safari: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Biome: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/IntelligencePlatform: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Shortcuts: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Suggestions: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Weather: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.accessibility.voicebanking: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.stocks: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.VoiceMemos.shared: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.secure-control-center-preferences: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.chronod: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.private.translation: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.calendar: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.testflight: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.newsd: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.siri.userfeedbacklearning: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.gamecenter: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.tips: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.spotlight: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.sharingd: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.weather: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/com.apple.systempreferences.cache: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.feedbacklogger: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.notes: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.tipsnext: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.Safari.SandboxBroker: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.transparency: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.reminders: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.mail: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.DeviceActivity: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/com.apple.Home.group: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.iCloudDrive: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.Photos.PhotosFileProvider: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.AppleSpell: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.mlhost: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Group Containers/group.com.apple.PegasusConfiguration: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.CloudPhotosConfiguration/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.PressAndHold/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.siri.SiriPrivateLearningAnalytics.SiriUserSegmentation/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.VoiceMemos: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.mlhost.TelemetryWorker/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.ax.KonaTTSSupport.KonaSynthesizer/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.CoreDevice.remotepairingd/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.Notes.LPPreviewGenerator/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish.upload/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.archiveutility: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.ScreenTimeAgent/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.LighthouseBitacoraFramework.BitacoraWorker/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.speech.MacinTalkFramework.WardaSynthesizer.x86-64/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.weather.widget/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.photos.ImageConversionService/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.Photos.PhotosFileProvider/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.quicklook.QuickLookUIService/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.iCal.CalendarWidgetExtension/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.contacts.donation-agent/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.photolibraryd/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.siri.media-indexer/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.speech.MacinTalkFramework.WardaSynthesizer.arm64/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.sharing.ShareSheetUI/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.BKAgentService/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.MobileSMS.spotlight/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.tonelibraryd/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.Maps/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.AMPDeviceDiscoveryAgent/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.systempreferences.AppleIDSettings/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.SafariPlatformSupport.Helper/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.microsoft.OneDriveLauncher/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/422E815A-C3C8-4F43-BAB9-D392BF34F5A0/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.Home: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.Safari: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.Safari.CacheDeleteExtension/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.lighthouse.SiriCoreMetricsWorker/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.wallpaper.extension.video/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.aiml.RepackagingWorker/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.AMPArtworkAgent/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.FollowUpSettings.FollowUpSettingsExtension/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.clock.WorldClockWidget/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.microsoft.Word/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.inputmethod.EmojiFunctionRowItem/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.news.widget/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.ScreenTimeWidgetApplication.ScreenTimeWidgetExtension/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.microsoft.OneDrive.FinderSync/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.AutoFillPanelService/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.speech.MacinTalkFramework.MacinTalkAUSP/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.QuickLookThumbnailing.extension.ThumbnailExtension-macOS/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.photoanalysisd/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.notificationcenterui/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.microsoft.OneDrive.FileProvider/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.CloudDocs.MobileDocumentsFileProvider: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.iCloudQuota.ICQFollowup/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.mail: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.MailShortcutsExtension/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.FamilyControlsAgent/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.siri.metrics.ExperimentationExtension/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.MobileSMS: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.SafariFoundation.CredentialProviderExtensionHelper/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.Music.MusicCacheExtension/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.calendar.CalendarFocusConfigurationExtension/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.LoginUserService/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish.mac-provider/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.AppStore/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.Siri/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.Notes: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.MailCacheDelete/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.mlhost.CloudWorker/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.siri.metrics.DevicePropertiesExtension/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.helpviewer/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.TextEdit/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.geod/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.news: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.TV.TVCacheExtension/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.iCloudDriveCore.telemetry-disk-checker/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.diskspaced/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.TestFlight.ServiceExtension/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.texttospeech.SiriAUSP/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.routined/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.microsoft.Excel/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.corerecents.recentsd/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.stocks.widget/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.Preview/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.UsageTrackingAgent/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.Passwords-Settings.extension/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.CoreRoutine.helperservice/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.siri.metrics.MetricsExtension/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.barebones.bbedit/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.stocks: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.Safari.SafariLinkExtension/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.quicklook.ui.helper/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.SiriNCService/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.ax.MauiTTSSupport.MauiAUSP/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.AirPlayUIAgent/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.voicebankingd/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.CloudDocs.iCloudDriveFileProvider/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish.NotificationService/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.mediaanalysisd/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.MobileSMS.MessagesActionExtension/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Containers/com.apple.Family/Data: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/ContainerManager: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/PersonalizationPortrait: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Metadata/CoreSpotlight: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Cookies: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/CoreFollowUp: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/StatusKit: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/DoNotDisturb: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Caches/com.apple.HomeKit: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Caches/CloudKit: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Caches/com.apple.Safari: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Caches/com.apple.findmy.fmfcore: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Caches/com.apple.containermanagerd: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Caches/FamilyCircle: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Caches/com.apple.homed: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Caches/com.apple.findmy.fmipcore: Operation not permitted
du: /System/Volumes/Data/Users/alexa/Library/Caches/com.apple.ap.adprivacyd: Operation not permitted
du: /System/Volumes/Data/Users/alexa/.Trash: Operation not permitted
du: /System/Volumes/Data/Users/maggiecox/Library/Autosave Information: Operation not permitted
du: /System/Volumes/Data/Users/maggiecox/Library/Mail: Operation not permitted
du: /System/Volumes/Data/Users/maggiecox/Library/ContainerManager: Operation not permitted
du: /System/Volumes/Data/Users/maggiecox/Library/Caches/com.apple.containermanagerd: Operation not permitted
du: /System/Volumes/Data/.TemporaryItems: Operation not permitted
du: /System/Volumes/iSCPreboot/.TemporaryItems: Operation not permitted
du: /private/var/networkd/db: Operation not permitted
du: /private/var/OOPJit: Operation not permitted
du: /private/var/db/appinstalld: Operation not permitted
du: /private/var/db/ExtensibleSSO/Configuration: Operation not permitted
du: /private/var/db/os_eligibility: Operation not permitted
du: /private/var/db/Spotlight: Operation not permitted
du: /private/var/db/sysdiagnose/com.apple.sysdiagnose: Operation not permitted
du: /private/var/db/SoC: Operation not permitted
du: /private/var/db/DumpPanic: Operation not permitted
du: /private/var/db/rmd/secure: Operation not permitted
du: /private/var/db/com.apple.backgroundtaskmanagement: Operation not permitted
du: /private/var/db/fpsd/dvp: Operation not permitted
du: /private/var/db/installcoordinationd: Operation not permitted
du: /private/var/db/Spotlight-V100: Operation not permitted
du: /private/var/db/oah: Operation not permitted
du: /private/var/db/Sandbox: Operation not permitted
du: /private/var/db/lockdown: Operation not permitted
du: /private/var/db/biome: Operation not permitted
du: /private/var/db/KernelExtensionManagement/Staging: Operation not permitted
du: /private/var/db/DifferentialPrivacy: Operation not permitted
du: /private/var/db/MobileIdentityService: Operation not permitted
du: /private/var/db/searchparty: Operation not permitted
du: /private/var/db/CoreDuet: Operation not permitted
du: /private/var/db/ConfigurationProfiles/Store: Operation not permitted
du: /private/var/folders/vn/j61v2nrj3tbf4c79n5r1cqbc0000gp/0/com.apple.LaunchServices.dv: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.ScreenTimeAgent/Store: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.lockoutagent: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.progressd/ClassKit: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.exchangesync: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.LaunchServices.dv: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/dmd: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.nsurlsessiond: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.SharedWebCredentials: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.FeatureStore: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/0/com.apple.routined/dv: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.appleaccountd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.syncdefaultsd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.transparencyd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.siriactionsd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.triald/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.ap.promotedcontentd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.appstoreagent/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.imtransferservices.IMTransferAgent/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.icloud.searchpartyd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.parsec-fbf/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.useractivityd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/gamed/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.fileproviderd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.nsurlsessiond/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.imtranscoding.IMTranscoderAgent/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.passd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.chrono/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.calaccessd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.remindd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.studentd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.parsecd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.identityservicesd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.sharingd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.shazamd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.bird/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.storekit/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.appstorecomponentsd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/homed/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.quicklook.ThumbnailsAgent/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.pluginkit/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.maps.destinationd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.AUHelperService/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.donotdisturbd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.imagent/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.weatherd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.imdpersistence.IMDPersistenceAgent/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/T/com.apple.amsengagementd/TemporaryItems: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/C/com.apple.siriactionsd/ShortcutsSandboxCache: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/C/com.apple.WebKit.WebContent.Sandbox: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/C/com.apple.WebKit.Networking.Sandbox: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/C/com.apple.quicklook.ThumbnailsAgent/com.apple.QuickLook.thumbnailcache: Operation not permitted
du: /private/var/folders/44/sc2qpf0j3sqddd67sfl3hg4h0000gn/C/com.apple.WebKit.GPU.Sandbox: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000sm00006d/0: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000sm00006d/C: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n000012800008k/T/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n000013800008t/T/com.apple.trustd/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000y800007k/0/com.apple.nsurlsessiond: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000y800007k/T/com.apple.nsurlsessiond/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/com.apple.ScreenTimeAgent/Store: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/com.apple.lockoutagent: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/com.apple.progressd/ClassKit: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/com.apple.exchangesync: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/dmd: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/com.apple.nsurlsessiond: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/com.apple.SharedWebCredentials: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/0/com.apple.routined/dv: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000z000007r/C/com.apple.quicklook.ThumbnailsAgent/com.apple.QuickLook.thumbnailcache: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000s0000068/T/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000s0000068/C/com.apple.WebKit.WebContent.Sandbox: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000s0000068/C/com.apple.WebKit.Networking.Sandbox: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n00000s0000068/C/com.apple.WebKit.GPU.Sandbox: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n000012r00008p/T/com.apple.MobileAccessoryUpdater/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n000012400008j/T/com.apple.appinstalld/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/0/com.apple.LaunchServices.dv: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.mobileassetd/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.dasd/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.revisiond/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/countryd/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.icloud.searchpartyd/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.aned/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.nehelper/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.AppStoreDaemon.StorePrivilegedODRService/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.GSSCred/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.kernelmanagerd/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/com.apple.wifianalyticsd/TemporaryItems: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/C/com.apple.WebKit.WebContent.Sandbox: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/C/com.apple.WebKit.Networking.Sandbox: Operation not permitted
du: /private/var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/C/com.apple.WebKit.GPU.Sandbox: Operation not permitted
du: /private/var/protected/trustd/private: Operation not permitted
du: /Users/alexa/Library/Application Support/CallHistoryTransactions: Operation not permitted
du: /Users/alexa/Library/Application Support/CloudDocs/session/db: Operation not permitted
du: /Users/alexa/Library/Application Support/com.apple.sharedfilelist: Operation not permitted
du: /Users/alexa/Library/Application Support/Knowledge: Operation not permitted
du: /Users/alexa/Library/Application Support/com.apple.TCC: Operation not permitted
du: /Users/alexa/Library/Application Support/FileProvider: Operation not permitted
du: /Users/alexa/Library/Application Support/FaceTime: Operation not permitted
du: /Users/alexa/Library/Application Support/com.apple.avfoundation/Frecents: Operation not permitted
du: /Users/alexa/Library/Application Support/CallHistoryDB: Operation not permitted
du: /Users/alexa/Library/Assistant/SiriVocabulary: Operation not permitted
du: /Users/alexa/Library/Daemon Containers: Operation not permitted
du: /Users/alexa/Library/Autosave Information: Operation not permitted
du: /Users/alexa/Library/IdentityServices: Operation not permitted
du: /Users/alexa/Library/Calendars: Operation not permitted
du: /Users/alexa/Library/Messages: Operation not permitted
du: /Users/alexa/Library/HomeKit: Operation not permitted
du: /Users/alexa/Library/Sharing: Operation not permitted
du: /Users/alexa/Library/com.apple.aiml.instrumentation: Operation not permitted
du: /Users/alexa/Library/Mail: Operation not permitted
du: /Users/alexa/Library/Trial: Operation not permitted
du: /Users/alexa/Library/AppleMediaServices: Operation not permitted
du: /Users/alexa/Library/DuetExpertCenter: Operation not permitted
du: /Users/alexa/Library/Accounts: Operation not permitted
du: /Users/alexa/Library/Safari: Operation not permitted
du: /Users/alexa/Library/Biome: Operation not permitted
du: /Users/alexa/Library/IntelligencePlatform: Operation not permitted
du: /Users/alexa/Library/Shortcuts: Operation not permitted
du: /Users/alexa/Library/Suggestions: Operation not permitted
du: /Users/alexa/Library/Weather: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.accessibility.voicebanking: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.stocks: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.VoiceMemos.shared: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.secure-control-center-preferences: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.chronod: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.private.translation: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.calendar: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.testflight: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.newsd: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.siri.userfeedbacklearning: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.gamecenter: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.tips: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.spotlight: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.sharingd: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.weather: Operation not permitted
du: /Users/alexa/Library/Group Containers/com.apple.systempreferences.cache: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.feedbacklogger: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.notes: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.tipsnext: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.Safari.SandboxBroker: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.transparency: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.reminders: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.mail: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.DeviceActivity: Operation not permitted
du: /Users/alexa/Library/Group Containers/com.apple.Home.group: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.iCloudDrive: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.Photos.PhotosFileProvider: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.AppleSpell: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.mlhost: Operation not permitted
du: /Users/alexa/Library/Group Containers/group.com.apple.PegasusConfiguration: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.CloudPhotosConfiguration/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.PressAndHold/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.siri.SiriPrivateLearningAnalytics.SiriUserSegmentation/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.VoiceMemos: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.mlhost.TelemetryWorker/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.ax.KonaTTSSupport.KonaSynthesizer/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.CoreDevice.remotepairingd/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Notes.LPPreviewGenerator/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish.upload/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.archiveutility: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.ScreenTimeAgent/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.LighthouseBitacoraFramework.BitacoraWorker/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.speech.MacinTalkFramework.WardaSynthesizer.x86-64/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.weather.widget/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.photos.ImageConversionService/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Photos.PhotosFileProvider/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.quicklook.QuickLookUIService/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.iCal.CalendarWidgetExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.contacts.donation-agent/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.photolibraryd/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.siri.media-indexer/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.speech.MacinTalkFramework.WardaSynthesizer.arm64/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.sharing.ShareSheetUI/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.BKAgentService/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.MobileSMS.spotlight/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.tonelibraryd/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Maps/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.AMPDeviceDiscoveryAgent/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.systempreferences.AppleIDSettings/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.SafariPlatformSupport.Helper/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.microsoft.OneDriveLauncher/Data: Operation not permitted
du: /Users/alexa/Library/Containers/422E815A-C3C8-4F43-BAB9-D392BF34F5A0/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Home: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Safari: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Safari.CacheDeleteExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.lighthouse.SiriCoreMetricsWorker/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.wallpaper.extension.video/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.aiml.RepackagingWorker/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.AMPArtworkAgent/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.FollowUpSettings.FollowUpSettingsExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.clock.WorldClockWidget/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.microsoft.Word/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.inputmethod.EmojiFunctionRowItem/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.news.widget/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.ScreenTimeWidgetApplication.ScreenTimeWidgetExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.microsoft.OneDrive.FinderSync/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.AutoFillPanelService/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.speech.MacinTalkFramework.MacinTalkAUSP/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.QuickLookThumbnailing.extension.ThumbnailExtension-macOS/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.photoanalysisd/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.notificationcenterui/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.microsoft.OneDrive.FileProvider/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.CloudDocs.MobileDocumentsFileProvider: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.iCloudQuota.ICQFollowup/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.mail: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.MailShortcutsExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.FamilyControlsAgent/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.siri.metrics.ExperimentationExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.MobileSMS: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.SafariFoundation.CredentialProviderExtensionHelper/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Music.MusicCacheExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.calendar.CalendarFocusConfigurationExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.LoginUserService/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish.mac-provider/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.AppStore/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Siri/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Notes: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.MailCacheDelete/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.mlhost.CloudWorker/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.siri.metrics.DevicePropertiesExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.helpviewer/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.TextEdit/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.geod/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.news: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.TV.TVCacheExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.iCloudDriveCore.telemetry-disk-checker/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.diskspaced/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.TestFlight.ServiceExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.texttospeech.SiriAUSP/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.routined/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.microsoft.Excel/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.corerecents.recentsd/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.stocks.widget/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Preview/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.UsageTrackingAgent/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Passwords-Settings.extension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.CoreRoutine.helperservice/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.siri.metrics.MetricsExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.barebones.bbedit/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.stocks: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Safari.SafariLinkExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.quicklook.ui.helper/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.SiriNCService/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.ax.MauiTTSSupport.MauiAUSP/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.AirPlayUIAgent/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.voicebankingd/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.CloudDocs.iCloudDriveFileProvider/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.appliedphasor.secure-shellfish.NotificationService/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.mediaanalysisd/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.MobileSMS.MessagesActionExtension/Data: Operation not permitted
du: /Users/alexa/Library/Containers/com.apple.Family/Data: Operation not permitted
du: /Users/alexa/Library/ContainerManager: Operation not permitted
du: /Users/alexa/Library/PersonalizationPortrait: Operation not permitted
du: /Users/alexa/Library/Metadata/CoreSpotlight: Operation not permitted
du: /Users/alexa/Library/Cookies: Operation not permitted
du: /Users/alexa/Library/CoreFollowUp: Operation not permitted
du: /Users/alexa/Library/StatusKit: Operation not permitted
du: /Users/alexa/Library/DoNotDisturb: Operation not permitted
du: /Users/alexa/Library/Caches/com.apple.HomeKit: Operation not permitted
du: /Users/alexa/Library/Caches/CloudKit: Operation not permitted
du: /Users/alexa/Library/Caches/com.apple.Safari: Operation not permitted
du: /Users/alexa/Library/Caches/com.apple.findmy.fmfcore: Operation not permitted
du: /Users/alexa/Library/Caches/com.apple.containermanagerd: Operation not permitted
du: /Users/alexa/Library/Caches/FamilyCircle: Operation not permitted
du: /Users/alexa/Library/Caches/com.apple.homed: Operation not permitted
du: /Users/alexa/Library/Caches/com.apple.findmy.fmipcore: Operation not permitted
du: /Users/alexa/Library/Caches/com.apple.ap.adprivacyd: Operation not permitted
du: /Users/alexa/.Trash: Operation not permitted
du: /Users/maggiecox/Library/Autosave Information: Operation not permitted
du: /Users/maggiecox/Library/Mail: Operation not permitted
du: /Users/maggiecox/Library/ContainerManager: Operation not permitted
du: /Users/maggiecox/Library/Caches/com.apple.containermanagerd: Operation not permitted
  0B        /.vol
  0B        /Volumes
  0B        /cores
5.5K        /dev
1.9M        /sbin
4.1M        /bin
2.4G        /opt
2.8G        /usr
7.7G        /Library
 11G        /private
125G        /Applications
251G        /Users
453G        /System
853G        /
alexa@Alexas-MacBook-Pro-2 blackroad-sandbox % tmutil listlocalsnapshots /   
sudo tmutil deletelocalsnapshots <timestamp>
zsh: parse error near `\n'
alexa@Alexas-MacBook-Pro-2 blackroad-sandbox % sudo tmutil thinlocalsnapshots / 999999999999
Thinned local snapshots:
alexa@Alexas-MacBook-Pro-2 blackroad-sandbox % ncdu ~
zsh: command not found: ncdu
alexa@Alexas-MacBook-Pro-2 blackroad-sandbox % brew install ncdu
# or
sudo apt install ncdu
==> Auto-updating Homebrew...
Adjust how often this is run with `$HOMEBREW_AUTO_UPDATE_SECS` or disable with
`$HOMEBREW_NO_AUTO_UPDATE=1`. Hide these hints with `$HOMEBREW_NO_ENV_HINTS=1` (see `man brew`).
==> Fetching downloads for: ncdu
✔︎ Bottle Manifest ncdu (2.9.2)                     [Downloaded   10.9KB/ 10.9KB]
✔︎ Bottle ncdu (2.9.2)                              [Downloaded  158.3KB/158.3KB]
==> Pouring ncdu--2.9.2.arm64_sonoma.bottle.tar.gz
🍺  /opt/homebrew/Cellar/ncdu/2.9.2: 7 files, 434.2KB
==> Running `brew cleanup ncdu`...
Disable this behaviour by setting `HOMEBREW_NO_INSTALL_CLEANUP=1`.
Hide these hints with `HOMEBREW_NO_ENV_HINTS=1` (see `man brew`).
Password:
Sorry, try again.
Password:
The operation couldn’t be completed. Unable to locate a Java Runtime.
Please visit http://www.java.com for information on installing Java.
alexa@Alexas-MacBook-Pro-2 blackroad-sandbox %