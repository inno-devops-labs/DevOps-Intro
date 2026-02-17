# Task 1

## 1.1 Boot Performance
```

(base) miraladutska@Noutbuk-Mira ~ % sysctl -n kern.boottime

{ sec = 1769720981, usec = 713374 } Fri Jan 30 00:09:41 2026
(base) miraladutska@Noutbuk-Mira ~ % uptime

19:36  up 18 days, 19:27, 2 users, load averages: 6.45 4.99 4.11
(base) miraladutska@Noutbuk-Mira ~ % system_profiler SPSoftwareDataType

Software:

    System Software Overview:

      System Version: macOS 26.2 (25C56)
      Kernel Version: Darwin 25.2.0
      Boot Volume: Macintosh HD
      Boot Mode: Normal
      Computer Name: Ноутбук — Mira
      User Name: Mira Ladutska (miraladutska)
      Secure Virtual Memory: Enabled
      System Integrity Protection: Enabled
      Time since boot: 18 дней, 19 часов, 27 минут

(base) miraladutska@Noutbuk-Mira ~ % uptime

19:36  up 18 days, 19:27, 2 users, load averages: 5.70 4.87 4.08
(base) miraladutska@Noutbuk-Mira ~ % w
19:36  up 18 days, 19:27, 2 users, load averages: 5.89 4.92 4.10
USER       TTY      FROM    LOGIN@  IDLE WHAT
miraladuts console  -      30Jan26 18days -
miraladuts s000     -      19:35       - w
(base) miraladutska@Noutbuk-Mira ~ % 
```
### Key Observations:
System uptime: The system has been running for 18 days and 19 hours without reboot.

Load average: Load averages are around 6.45 / 4.99 / 4.11, which indicates moderate to high CPU activity.

Boot time: The machine last booted on January 30, 2026.

Unusual delays: No boot issues are visible, but the load average suggests background processes may be consuming resources.

---

## 1.2 Process Forensics
```
(base) miraladutska@Noutbuk-Mira ~ % ps -Ao pid,ppid,comm,%mem,%cpu -r | head -n 6

  PID  PPID COMM             %MEM  %CPU
38235     1 /System/Library/  0.3  23.1
32477     1 /System/Library/  0.4  20.4
55192     1 /System/Library/  0.4  18.6
30067     1 /System/Library/  0.3  17.4
 3319     1 /System/Library/  0.4  11.0
(base) miraladutska@Noutbuk-Mira ~ % ps -Ao pid,ppid,comm,%mem,%cpu | sort -k4 -nr | head -n 6

33220     1 /System/Volumes/  4.1   8.7
51231     1 /System/Applicat  1.9  23.5
  591     1 /System/Library/  1.9   6.7
40308     1 /System/Library/  1.5   1.9
41711     1 /System/Library/  1.4   3.3
33226     1 /System/Library/  1.0  11.5
(base) miraladutska@Noutbuk-Mira ~ % ps -Ao pid,ppid,comm,%mem,%cpu | sort -k5 -nr | head -n 6

38235     1 /System/Library/  0.3  22.0
32477     1 /System/Library/  0.4  17.9
55192     1 /System/Library/  0.3  16.9
30067     1 /System/Library/  0.3  15.8
33226     1 /System/Library/  0.9  11.0
33220     1 /System/Volumes/  4.1  10.7
(base) miraladutska@Noutbuk-Mira ~ % top -o cpu

(base) miraladutska@Noutbuk-Mira ~ %

```

### Key Observations
Highest memory process: PID 33220 is using the most memory at 4.1% MEM, making it the top memory-consuming process.

Highest CPU process: PID 38235 shows the highest CPU usage at approximately 23% CPU.

Background vs user processes: Most of the top processes are system-level services located under /System/Library/, indicating that background macOS daemons are responsible for most resource usage rather than user applications.

**Answer:**

The top memory-consuming process is: PID 33220 (/System/Volumes/...)

---

## 1.3 Service Analysis

```
(base) miraladutska@Noutbuk-Mira ~ % launchctl list

PID	Status	Label
-	0	com.apple.SafariHistoryServiceAgent
-	-9	com.apple.progressd
-	0	com.apple.enhancedloggingd
-	-9	com.apple.cloudphotod
-	-9	com.apple.MENotificationService
1849	0	com.apple.Finder
-	-9	com.apple.homed
-	-9	com.apple.dataaccess.dataaccessd
-	0	com.apple.quicklook
-	0	com.apple.parentalcontrols.check
-	0	us.zoom.updater
1109	0	com.apple.mediaremoteagent
1157	0	com.apple.FontWorker
971	0	com.apple.bird
-	0	com.apple.amp.mediasharingd
-	-9	com.apple.knowledgeconstructiond
41055	-9	com.apple.inputanalyticsd
-	0	com.apple.familycontrols.useragent
-	0	com.apple.AssetCache.agent
41846	0	com.apple.GameController.gamecontrolleragentd
7607	0	com.apple.universalaccessAuthWarn
-	0	com.apple.UserPictureSyncAgent
944	0	com.apple.nsurlsessiond
-	-9	com.apple.devicecheckd
-	0	com.apple.syncservices.uihandler
4128	-9	com.apple.iconservices.iconservicesagent
-	-9	com.apple.diagnosticextensionsd
-	-9	com.apple.intelligenceplatformd
37394	-9	com.apple.SafariBookmarksSyncAgent
-	0	com.apple.cmio.LaunchCMIOUserExtensionsAgent
-	-9	com.apple.LinkedNotesUIService
-	-9	com.apple.ndoagent
1383	0	com.apple.wallpaper.agent
-	0	com.apple.bookassetd
-	0	com.apple.ManagedClientAgent.agent
1944	0	application.com.figma.agent.12357889.33683762
-	-9	com.apple.localizationswitcherd
-	0	com.apple.screensharing.agent
1894	0	com.apple.commerce
-	0	com.apple.AddressBook.SourceSync
-	-9	com.apple.installerauthagent
-	0	com.apple.languageassetd
-	0	com.apple.familynotificationd
40716	-9	com.apple.ManagedSettingsAgent
41976	-9	com.apple.photolibraryd
-	0	com.apple.mbfloagent.B1000052-6A86-4C09-B662-133940BDC927
-	0	com.apple.xpc.otherbsd
-	0	com.apple.sysdiagnose_agent
-	-9	com.apple.ThreadCommissionerService
-	-9	com.apple.tipsd
-	0	com.apple.stickersd
-	-9	com.apple.bluetoothuserd
-	0	com.apple.timezoneupdates.tznotify
1942	0	com.apple.TextInputMenuAgent
-	0	com.apple.bluetoothUIServer
-	0	com.apple.accessibility.LiveTranscriptionAgent
-	0	com.apple.assistant_service
41841	-9	com.apple.CommCenter
5011	0	com.apple.trustd.agent
-	0	com.apple.MailServiceAgent
-	0	com.apple.mdworker.mail
-	0	com.apple.appkit.xpc.ColorSampler
923	0	com.apple.cfprefsd.xpc.agent
-	0	com.apple.coreimportd
-	0	com.apple.CoreDevice.remotepairingd
-	-9	com.apple.TrustedPeersHelper
-	0	com.apple.cvmsCompAgent3600_arm64_1
-	0	com.apple.DataDetectorsLocalSources
-	0	com.apple.unmountassistant.useragent
-	0	com.apple.facetimemessagestored
-	0	com.apple.AutoFillPanel
-	-9	com.apple.peopled
-	0	com.apple.remotecompositorclientd
-	0	com.apple.PosterBoard
41871	-9	com.apple.replicatord
-	-9	com.apple.keyboardservicesd
41889	-9	com.apple.accessibility.axassetsd
40381	-9	com.apple.quicklook.ThumbnailsAgent
3322	-9	com.apple.Safari.PasswordBreachAgent
-	0	com.apple.csuseragent
-	0	com.apple.asktod
1078	0	com.apple.WindowManager.agent
31472	-9	com.apple.ContextStoreAgent
-	0	com.apple.AOSPushRelay
-	0	com.apple.accessibility.AXVisualSupportAgent
-	-9	com.apple.xpc.loginitemregisterd
-	-9	com.apple.webprivacyd
29695	0	com.apple.applespell
-	0	com.apple.coreservices.UASharedPasteboardProgressUI
-	0	com.apple.uarppersonalizationd
-	0	com.apple.screensharing.menuextra
-	0	com.apple.warmd_agent
-	-9	com.apple.voicebankingd
-	0	com.apple.gamesaved
-	0	com.apple.universalaccesscontrol
13582	-9	com.apple.Safari.SafeBrowsing.Service
-	0	com.apple.notes.exchangenotesd
-	0	com.apple.findmymacmessenger
-	0	com.apple.FilesystemUI
-	0	com.apple.maps.destinationd
44621	-9	com.apple.ScreenTimeAgent
-	0	com.apple.pluginkit.pkreporter
-	0	com.apple.arkitd
-	0	com.apple.systemprofiler
-	-9	com.apple.homeenergyd
2629	-9	com.apple.cloudd
-	-9	com.apple.noticeboard.agent
2062	0	com.apple.UserNotificationCenterAgent
1123	0	com.apple.cmfsyncagent
-	0	com.apple.dt.CommandLineTools.installondemand
-	0	com.apple.ATS.FontValidator
1522	0	com.apple.diagnostics_agent
37687	0	application.com.microsoft.Word.35443871.35509774
-	0	com.apple.appleseed.seedusaged
-	-9	com.apple.LocalAuthentication.UIAgent
-	-9	com.apple.ap.adprivacyd
-	0	com.apple.callhistoryd
-	-9	com.apple.ap.promotedcontentd
-	-9	com.apple.apfsuseragent
-	0	com.apple.intelligencetasksd
40635	-9	com.apple.networkserviceproxy
1276	0	com.apple.controlcenter
-	-9	com.apple.contacts.postersyncd
2140	0	com.apple.AMPLibraryAgent
23428	0	com.openssh.ssh-agent
-	-9	com.apple.amsondevicestoraged
-	0	com.apple.tonelibraryd
-	-9	com.apple.CloudPhotosConfiguration
-	0	com.apple.security.KeychainStasher
-	-9	com.apple.ctcategories.service
41886	-9	com.apple.ctkd
-	0	com.apple.package-script-service
41890	-9	com.apple.secinitd
-	0	com.apple.speech.speechsynthesisd.x86_64
-	0	com.apple.mediacontinuityd
-	-9	com.apple.contacts.donation-agent
-	0	com.apple.ServicesUIAgent
37589	-9	com.apple.synapse.contentlinkingd
-	0	com.microsoft.update.agent
-	-9	com.apple.XprotectFramework.PluginService
-	0	com.apple.ctkbind
-	0	com.apple.mediastream.mstreamd
-	0	com.apple.alf.useragent
-	0	com.apple.mbfloagent.54F16C42-5273-42B9-80F0-7348E00F864F
-	0	com.apple.SiriTTSTrainingAgent
-	-9	com.apple.triald
30645	-9	com.apple.tccd
-	0	com.apple.nexusd
40729	-9	com.apple.StatusKitAgent
-	-9	com.apple.diagnosticspushd
41843	-9	com.apple.replayd
38221	-9	com.apple.coreservices.uiagent
38975	-9	com.apple.icloud.searchpartyuseragent
-	0	com.apple.AccessibilityVisualsAgent
-	0	com.apple.installd.user
-	-9	com.apple.privatecloudcomputed
-	-9	com.apple.textunderstandingd
41870	-9	com.apple.liveactivitiesd
1027	0	com.apple.akd
-	-9	com.apple.CallHistoryPluginHelper
-	-9	com.apple.jetpackassetd
-	-9	com.apple.homeeventsd
-	-9	com.apple.GamePolicyAgent
-	0	com.apple.mbproximityhelper
-	-9	com.apple.appplaceholdersyncd
-	0	com.apple.storeaccountd
-	0	com.apple.AddressBook.AssistantService
-	0	com.apple.PIPAgent
1036	0	com.apple.cmio.ContinuityCaptureAgent
-	0	com.apple.mbfloagent
-	0	com.apple.searchtoold
-	-9	com.apple.printtool.agent
-	0	com.apple.callintelligenced
-	-9	com.apple.askpermissiond
-	0	com.apple.previewshellmacapp
-	0	com.microsoft.VSCode.ShipIt
-	0	com.apple.ssinvitationagent
-	0	com.apple.webinspectord
-	-9	com.apple.avatarsd
-	0	com.apple.speech.synthesisserver
-	-9	com.apple.FeatureAccessAgent
31971	0	com.apple.storeuid
41988	0	com.apple.rcd
-	0	com.apple.printuitool.agent
-	0	com.apple.NVMeAgent
-	0	com.apple.speech.speechdatainstallerd
-	0	com.apple.AOSHeartbeat
1817	0	com.apple.CryptoTokenKit.ahp.agent
41893	-9	com.apple.SafariNotificationAgent
-	0	com.apple.coredatad
-	0	com.apple.mbfloagent.955D0E39-76C3-4EA3-8CFA-7F1E31698268
41882	-9	com.apple.remindd
-	0	com.apple.appsleep
-	0	com.microsoft.SyncReporter
1194	0	com.apple.duetexpertd
1112	0	com.apple.coreservices.useractivityd
-	0	com.apple.screencaptureui.agent
-	0	com.apple.cvmsCompAgent3600_x86_64_1
-	0	com.apple.netauth.user.auth
1094	0	com.apple.ViewBridgeAuxiliary
-	0	com.apple.mbbackgrounduseragent
-	0	com.apple.cvmsCompAgent_x86_64
938	0	com.apple.lsd
-	-9	com.apple.siri.context.service
-	-9	com.apple.fskit.fskit_agent
41879	-9	com.apple.pluginkit.pkd
-	0	com.apple.CharacterPicker.RemoteGenerationViewService
-	0	com.apple.security.XPCTimeStampingService
-	0	com.apple.Virtualization.EventTap
-	-9	com.apple.webkit.webpushd
-	-9	com.apple.weatherd
-	-9	com.apple.cache_delete
-	0	com.apple.symptomsd-diag.agent
1859	0	com.apple.AMPDeviceDiscoveryAgent
-	0	com.apple.accessibility.dfrhud
-	-9	com.apple.CallHistorySyncHelper
-	-9	com.apple.colorsync.useragent
-	-9	com.apple.analyticsagent
-	-9	com.apple.appleaccountd
37591	-9	com.apple.parsecd
-	-9	com.apple.mlruntimed
1847	0	com.apple.Dock.agent
-	0	com.apple.parsec-fbf
38998	-9	com.apple.dmd
-	-9	com.apple.transparencyd
-	0	com.apple.usbnotificationagent
-	-9	com.apple.AppSSOAgent
89720	0	com.apple.mbuseragent
-	0	com.apple.security.cloudkeychainproxy3
927	0	com.apple.UserEventAgent-Aqua
1043	0	com.apple.followupd
41757	0	application.com.apple.Terminal.1152921500311913407.1152921500311913412
955	0	com.apple.identityservicesd
34103	-9	com.apple.telephonyutilities.callservicesd
-	0	com.apple.DwellControl
-	-9	com.apple.generativeexperiencesd
-	-9	com.apple.XProtect.agent.scan
-	-9	com.apple.storekitagent
-	0	jetbrains.vmoptions
32182	0	com.apple.security.DiskUnmountWatcher
41657	-9	com.apple.CoreLocationAgent
-	0	com.apple.StorageManagement.Service
-	0	com.apple.securemessagingagent
-	-9	com.apple.SecureBackupDaemon
-	0	com.apple.security.agent
40695	-9	com.apple.backgroundtaskmanagement.agent
-	0	com.apple.intelligenceflowd
41848	-9	com.apple.businessservicesd
-	0	com.apple.cfnetwork.AuthBrokerAgent
41850	-9	com.apple.feedbackd
-	0	com.apple.storedownloadd
-	0	com.apple.SpacesTouchBarAgent.app
14128	-9	com.apple.BTServer.cloudpairing
-	0	us.zoom.updater.login.check
-	0	com.apple.managedcorespotlightd
1007	0	com.apple.coreservices.sharedfilelistd
935	0	com.apple.pboard
-	0	com.apple.nowplayingtouchui
-	0	com.apple.MobileAccessoryUpdater.fudHelperAgent
-	-9	com.apple.reversetemplated
-	-9	com.apple.BTServer.le.agent
-	0	com.apple.AskPermissionUI
-	0	com.apple.thermaltrap
945	0	com.apple.rapportd
-	-9	com.apple.SoftwareUpdateNotificationManager
-	0	com.apple.DistributionKit.DistributionHelper
-	0	com.apple.accounts.dom
1816	0	com.apple.TextInputUI.xpc.CursorUIViewService
-	0	com.apple.metadata.mdflagwriter
-	-9	com.apple.DictionaryServiceHelper
-	0	com.apple.mdworker.shared
-	0	com.apple.mdworker.single.x86_64
-	0	com.apple.usermanagerhelper
-	1	com.apple.installandsetup.migrationhelper.user
940	0	com.apple.containermanagerd
-	-9	com.apple.imdpersistence.IMDPersistenceAgent
-	0	com.apple.TrustEvaluationAgent
-	0	com.apple.Notes.datastore
-	0	com.apple.mbfloagent.3D9C67C5-6FB9-4D3C-873F-DDC04483E616
41904	-9	com.apple.mlhostd
-	0	com.apple.preference.displays.MirrorDisplays
-	-9	com.apple.IOUIAgent
39131	0	com.apple.neagent.878568F8-CCE5-4157-8315-22F20DC8FB0A
-	0	com.apple.previewshellapp
6150	0	com.apple.managedappdistributionagent
956	0	com.apple.accountsd
-	-9	com.apple.cdpd
-	-9	com.apple.routined
41865	-9	com.apple.siriactionsd
-	0	com.apple.KeyboardAccessAgent
-	0	com.apple.ecosystemagent
-	0	com.apple.mbfloagent.BA42BAE3-0C67-4DDC-A760-DFB1B1952D1B
937	0	com.apple.BiomeAgent
-	0	com.apple.storelegacy
-	0	com.apple.OSDUIHelper
41895	-9	com.apple.audio.AudioComponentRegistrar
41873	-9	com.apple.AssetCacheLocatorService
-	0	com.apple.DiagnosticsReporter
950	0	com.apple.lockoutagent
-	0	com.apple.videosubscriptionsd
40894	-9	com.apple.pbs
-	0	com.apple.calendar.CalendarAgentBookmarkMigrationService
1090	0	com.apple.notificationcenterui.agent
-	-9	com.apple.protectedcloudstorage.protectedcloudkeysyncing
1815	0	com.apple.imklaunchagent
1011	0	com.apple.FileProvider
-	0	com.apple.imcore.imtransferagent
41869	-9	com.apple.mobiletimerd
-	0	com.apple.btsa
1935	0	com.apple.icdd
-	0	com.apple.ckdiscretionaryd
-	-9	com.apple.EscrowSecurityAlert
-	-9	com.apple.MTLAssetUpgraderD
51246	0	com.apple.ptpcamerad
2760	0	com.apple.metadata.mdwrite
32649	0	application.hossin.asaadi.V2Box.23669551.23669557
-	0	com.apple.mbfloagent.2B1ECD2F-2914-4C3D-985E-22E884F21FF6
-	0	com.apple.loginwindow.LWWeeklyMessageTracer
-	0	com.apple.spotlightknowledged
-	0	com.apple.securityuploadd
-	-9	com.apple.lockdownmoded
-	0	com.apple.companiond
-	0	com.apple.RapportUIAgent
-	-9	com.apple.siriknowledged
2630	0	com.apple.powerchime
987	0	com.apple.sharingd
-	-9	com.apple.seserviced
-	-9	com.apple.mobilerepaird
-	0	com.apple.iCloudUserNotificationsd
-	-9	com.apple.metrickitd
-	0	com.apple.storeassetd
995	0	com.apple.familycircled
-	-9	com.apple.filevaultd
-	0	com.apple.FontRegistryUIAgent
-	-9	com.apple.RemoteManagementAgent
-	0	com.apple.sportsd
40764	-9	com.apple.TextInputSwitcher
-	-9	com.apple.intelligentroutingd
-	-9	com.apple.AMPArtworkAgent
1095	0	com.apple.imagent
-	-9	com.apple.sidecar-relay
-	0	com.apple.cloudsettingssyncagent
-	-9	com.apple.assistant_cdmd
-	-9	com.apple.photoanalysisd
-	0	com.apple.syncservices.SyncServer
3417	0	com.apple.imautomatichistorydeletionagent
1848	0	com.apple.SystemUIServer.agent
-	0	com.apple.PackageUIKit.InstallStatus
30695	-9	com.apple.talagent
31447	-9	com.apple.suggestd
-	0	com.apple.navd
-	0	com.apple.appleidsetupd
-	0	com.apple.RemoteDesktop.agent
53777	-9	com.apple.iCloudNotificationAgent
-	-9	com.apple.amsaccountsd
-	0	com.apple.VoiceOver
-	-9	com.apple.Maps.mapssyncd
-	-9	com.apple.swtransparencyd
-	0	com.apple.gputoolsserviced
951	0	com.apple.usernotificationsd
-	-9	com.apple.FamilyControlsAgent
1767	0	com.apple.spotlightknowledged.importer
-	0	com.apple.AssistiveControl
-	0	com.apple.mdworker.single.arm64
-	0	com.apple.ContainerMigrationService
918	0	com.apple.secd
36521	-9	com.apple.hiservices-xpcservice
-	-9	com.apple.BKAgentService
-	0	com.apple.cvmsCompAgent_x86_64_1
31349	-9	com.apple.assistantd
-	-9	com.apple.siriinferenced
-	-9	com.apple.studentd
2417	0	com.apple.FollowUpUI
1111	0	com.apple.videoconference.camera
-	0	com.apple.corespotlightservice
1102	0	com.apple.uikitsystemapp
-	0	com.apple.controlstrip
-	-9	com.apple.financed
41883	-9	com.apple.findmy.findmylocateagent
-	0	com.apple.previewsd
-	-9	com.apple.mediaanalysisd
-	0	com.apple.DiskArbitrationAgent
-	0	com.todesktop.230313mzl4w4u92.ShipIt
-	0	com.apple.mbfloagent.BEF42333-1CE3-417D-AC87-9D02569042F8
41847	-9	com.apple.assessmentagent
51231	0	application.com.apple.Preview.1152921500311897665.1152921500311897670
-	0	com.apple.exchange.exchangesyncd
-	0	com.apple.testmanagerd
-	0	com.apple.dt.AutomationModeUI
41977	-9	com.apple.scopedbookmarksagent.xpc
2161	0	com.apple.ensemble
-	-9	com.apple.ReportCrash
-	0	com.apple.biomesyncd
-	0	com.microsoft.OneDriveStandaloneUpdater
-	-9	com.apple.ciphermld
22430	-9	com.apple.UsageTrackingAgent
1120	0	com.apple.email.maild
-	-9	com.apple.donotdisturbd
-	0	com.apple.accessorysensormgrd
-	0	com.apple.locationaccessstored
-	0	com.apple.menuextra.battery.helper
-	0	com.apple.appleseed.seedusaged.postinstall
-	0	com.apple.Maps.mapspushd
-	0	com.apple.coreidvd
-	0	com.apple.voicememod
-	-9	com.apple.gamed
-	0	com.apple.STMUIHelper
39248	-9	com.apple.intelligencecontextd
37469	-9	com.apple.knowledge-agent
-	0	com.apple.midiserver
2131	0	com.apple.mobiledeviceupdater
1034	0	com.apple.AccessibilityUIServer
-	-9	com.apple.communicationtrustd
-	0	com.apple.helpd
-	-9	com.apple.icloudmailagent
-	0	com.apple.quicklook.ui.helper
-	0	com.apple.GameOverlayUI
960	0	com.apple.wifi.WiFiAgent
-	0	com.apple.screensharing.MessagesAgent
-	0	com.apple.diskspaced
-	0	com.google.GoogleUpdater.wake
1201	0	com.apple.passd
33457	0	application.com.microsoft.VSCode.35898448.35898454
-	0	com.apple.mbfloagent.1E08273B-A852-47E4-8ED9-CB11D7C3ECCC
-	0	com.apple.DictationIM
-	-9	com.apple.sociallayerd
-	0	com.apple.mdmclient.agent
41887	0	com.apple.iCloudHelper
-	0	com.apple.CharacterPicker.FileService
-	-9	com.apple.keychainsharingmessagingd
-	0	com.apple.MessageUIMacHelperService
-	0	com.apple.cvmsCompAgent3425AMD_x86_64
-	0	com.apple.gamecontroller.ConfigService
-	0	com.apple.security.XPCKeychainSandboxCheck
-	-9	com.apple.podcasts.PodcastContentService
37120	-9	com.apple.CoreAuthentication.agent
41049	-9	com.apple.syncdefaultsd
-	0	com.apple.sidecar-display-agent
1086	0	com.apple.chronod
35780	-9	com.apple.accessibility.heard
998	0	com.apple.corespeechd
-	-9	com.apple.geoanalyticsd
-	0	com.apple.AMPSystemPlayerAgent
-	-9	com.apple.itunescloudd
-	0	com.apple.scrod
-	-9	com.apple.spindump_agent
-	-9	com.apple.frauddefensed
-	0	com.apple.AquaAppearanceHelper
41219	-9	com.apple.AuthenticationServicesCore.AuthenticationServicesAgent
-	0	com.apple.cvmsCompAgent_arm64
-	-9	com.apple.milod
-	0	com.apple.bookdatastored
40424	-9	com.apple.security.keychain-circle-notification
-	0	com.apple.appstorecomponentsd
-	-9	com.apple.icloud.findmydeviced.findmydevice-user-agent
-	0	com.apple.XProtect.agent.scan.startup
-	-9	com.apple.amsengagementd
-	-9	com.apple.betaenrollmentagent
-	0	com.apple.AirPortBaseStationAgent
-	-9	com.apple.proactiveeventtrackerd
31427	-9	com.apple.proactived
-	-9	com.apple.ModelCatalogAgent
933	0	com.apple.universalaccessd
37397	-9	com.apple.linkd
-	0	com.apple.accessibility.MotionTrackingAgent
-	0	com.apple.neagent
-	-9	com.apple.SafariLaunchAgent
-	0	com.apple.idsfoundation.IDSRemoteURLConnectionAgent
-	0	com.apple.textcomposerd
-	-9	com.apple.recentsd
27311	-9	com.apple.spotlightknowledged.updater
33220	0	application.com.apple.Safari.327803.328687
-	0	com.apple.transparencyStaticKey
-	-9	com.apple.sirittsd
-	-9	com.apple.dprivacyd
946	0	com.apple.usernoted
-	-9	com.apple.geodMachServiceBridge
1887	0	com.apple.Safari.History
-	-9	com.apple.translationd
-	0	com.apple.AddressBook.abd
-	0	com.apple.bluetoothaudiod
41885	-9	com.apple.calaccessd
41728	-9	com.apple.managedcorespotlightd.C4714B47-4382-C226-DE0D-4D1F20572560
-	0	com.apple.ScreenReaderUIServer
-	0	com.apple.newsd
-	0	com.apple.systemsettingsagent
40662	-9	com.apple.swcd
-	0	com.apple.symptomsd.distributed-agent
1940	0	com.apple.AirPlayUIAgent
-	-9	com.apple.backgroundassets.user
-	0	com.apple.cvmsCompAgent_arm64_1
-	-9	com.apple.shazamd
1055	0	com.apple.corespotlightd
41861	-9	com.apple.naturallanguaged
-	0	com.apple.netauth.user.gui
-	0	com.apple.watchlistd
1076	0	com.apple.xtyped
-	0	com.apple.TMHelperAgent
22749	255	com.apple.Spotlight
31974	-9	com.apple.appstoreagent
-	0	com.apple.AMPDevicesAgent
41894	-9	com.apple.accessibility.mediaaccessibilityd
-	0	com.apple.cvmsCompAgent3425AMD_x86_64_1
-	-9	com.apple.mdworker.sizing
-	0	com.apple.SpeechRecognitionCore.brokerd
1623	0	com.apple.metadata.mdbulkimport
-	-9	com.apple.iokit.IOServiceAuthorizeAgent
-	0	com.apple.cvmsCompAgent3600_arm64
40725	-9	com.apple.WorkflowKit.ShortcutsViewService
-	-9	com.apple.carboncore.csnameddata
41986	0	com.apple.mdworker.shared.07000000-0700-0000-0000-000000000000
41884	-9	com.apple.contactsd
-	0	com.apple.cvmsCompAgent3600_x86_64
-	0	com.apple.speech.speechsynthesisd.arm64
-	0	com.apple.CoreRoutine.helperservice
896	0	com.apple.distnoted.xpc.agent
-	-9	com.apple.SetStoreUpdateService
41915	-9	com.apple.geod
(base) miraladutska@Noutbuk-Mira ~ % ls /System/Library/LaunchDaemons

bootps.plist
com.apple.AirPlayXPCHelper.plist
com.apple.AppSSOAgent.login.plist
com.apple.AppSSODaemon.plist
com.apple.AppleCredentialManagerDaemon.plist
com.apple.AppleQEMUGuestAgent.plist
com.apple.AssetCache.builtin.plist
com.apple.AssetCacheLocatorService.plist
com.apple.AssetCacheManagerService.plist
com.apple.AssetCacheTetheratorService.plist
com.apple.BTServer.le.plist
com.apple.BlueTool.plist
com.apple.CSCSupportd.plist
com.apple.ContainerMigrationService.plist
com.apple.CoreAuthentication.daemon.plist
com.apple.CrashReporterSupportHelper.plist
com.apple.CryptoTokenKit.ahp.plist
com.apple.DataDetectorsSourceAccess.plist
com.apple.DesktopServicesHelper.plist
com.apple.DumpGPURestart.plist
com.apple.DumpPanic.Accessory.plist
com.apple.DumpPanic.plist
com.apple.FileCoordination.plist
com.apple.GSSCred.plist
com.apple.GameController.gamecontrollerd.plist
com.apple.IFCStart.plist
com.apple.IOAccelMemoryInfoCollector.plist
com.apple.InstallerDiagnostics.installerdiagd.plist
com.apple.InstallerDiagnostics.installerdiagwatcher.plist
com.apple.InstallerProgress.plist
com.apple.Kerberos.digest-service.plist
com.apple.Kerberos.kadmind.plist
com.apple.Kerberos.kcm.plist
com.apple.Kerberos.kdc.plist
com.apple.Kerberos.kpasswdd.plist
com.apple.KernelEventAgent.plist
com.apple.ManagedClient.enroll.plist
com.apple.ManagedClient.mechanism.plist
com.apple.ManagedClient.plist
com.apple.ManagedClient.startup.plist
com.apple.MobileFileIntegrity.plist
com.apple.NetworkLinkConditioner.plist
com.apple.NetworkSharing.plist
com.apple.ODSAgent.plist
com.apple.PasswordService.plist
com.apple.PerfPowerServices.plist
com.apple.PerfPowerServicesExtended.plist
com.apple.PowerUIAgent.plist
com.apple.RFBEventHelper.plist
com.apple.RemoteDesktop.PrivilegeProxy.plist
com.apple.ReportCrash.Root.plist
com.apple.ReportMemoryException.plist
com.apple.ReportSystemMemory.plist
com.apple.SCHelper.plist
com.apple.SafeEjectGPUStartupDaemon.plist
com.apple.SubmitDiagInfo.plist
com.apple.TrustEvaluationAgent.system.plist
com.apple.UpdateSettings.plist
com.apple.UserEventAgent-System.plist
com.apple.UserNotificationCenter.plist
com.apple.Virtualization.AppleVirtualPlatformHIDBridge.plist
com.apple.WindowServer.plist
com.apple.WirelessRadioManager-osx.plist
com.apple.accessoryd.plist
com.apple.accessoryupdaterd.plist
...
com.apple.touchbarserver.plist
com.apple.tracd.plist
com.apple.triald.system.plist
com.apple.trustd.plist
com.apple.trustdFileHelper.plist
com.apple.tzlinkd.plist
com.apple.uarpassetmanagerd.plist
com.apple.uarpd.plist
com.apple.uarphidd.plist
com.apple.ucupdate.plist
com.apple.uninstalld.plist
com.apple.unmountassistant.sysagent.plist
com.apple.usbaudiod.plist
com.apple.usbctelemetryd.plist
com.apple.usbpowerd.plist
com.apple.usbsmartcardreaderd.plist
com.apple.uucp.plist
com.apple.vsdbutil.plist
com.apple.wallpaper.export.plist
com.apple.warmd.plist
com.apple.watchdogd.plist
com.apple.wifiFirmwareLoader.plist
com.apple.wifianalyticsd.plist
com.apple.wifip2pd.plist
com.apple.wifivelocityd.plist
com.apple.xartstorageremoted.plist
com.apple.xpc.roleaccountd.plist
com.apple.xpc.smd.plist
com.apple.xpc.uscwoap.plist
com.apple.xsan.plist
com.apple.xscertadmin.plist
com.apple.xscertd-helper.plist
com.apple.xscertd.plist
com.vix.cron.plist
ntalk.plist
org.apache.httpd.plist
org.cups.cups-lpd.plist
org.cups.cupsd.plist
org.net-snmp.snmpd.plist
org.openldap.slapd.plist
ssh.plist
tftp.plist
(base) miraladutska@Noutbuk-Mira ~ % ls /System/Library/LaunchAgents

com.apple.AMPArtworkAgent.plist
com.apple.AMPDeviceDiscoveryAgent.plist
com.apple.AMPDevicesAgent.plist
com.apple.AMPLibraryAgent.plist
com.apple.AMPSystemPlayerAgent.plist
com.apple.AOSHeartbeat.plist
com.apple.AOSPushRelay.plist
com.apple.AccessibilityVisualsAgent.plist
com.apple.AddressBook.AssistantService.plist
com.apple.AddressBook.SourceSync.plist
com.apple.AddressBook.abd.plist
com.apple.AirPlayUIAgent.plist
com.apple.AirPortBaseStationAgent.plist
com.apple.AppSSOAgent.plist
com.apple.AquaAppearanceHelper.agent.plist
com.apple.AskPermissionUI.plist
com.apple.AssetCache.agent.plist
com.apple.AssetCacheLocatorService.plist
com.apple.AssistiveControl.plist
com.apple.AuthenticationServicesCore.AuthenticationServicesAgent.plist
com.apple.AutoFillPanel.plist
com.apple.BTServerAgent.le.plist
com.apple.BiomeAgent.plist
com.apple.CallHistoryPluginHelper.plist
com.apple.CallHistorySyncHelper.plist
com.apple.CloudSettingsSyncAgent.plist
com.apple.CommCenter-osx.plist
com.apple.ContainerMigrationService.plist
com.apple.ContextStoreAgent.plist
com.apple.CoreAuthentication.agent.plist
com.apple.CoreLocationAgent.plist
com.apple.CryptoTokenKit.ahp.agent.plist
com.apple.DataDetectorsLocalSources.plist
com.apple.DiagnosticsReporter.plist
com.apple.DictationIM.plist
com.apple.DiskArbitrationAgent.plist
com.apple.Dock.plist
com.apple.DwellControl.plist
com.apple.EscrowSecurityAlert.plist
com.apple.ExpansionSlotNotification.plist
com.apple.FamilyControlsAgent.plist
com.apple.FeatureAccessAgent.plist
com.apple.FileProvider.plist
com.apple.FilesystemUI.plist
com.apple.Finder.plist
com.apple.FolderActionsDispatcher.plist
com.apple.FollowUpUI.plist
com.apple.FontRegistryUIAgent.plist
com.apple.FontValidator.plist
com.apple.FontWorker.plist
com.apple.GameController.gamecontrolleragentd.plist
com.apple.GamePolicyAgent.plist
com.apple.IOUIAgent.plist
com.apple.KeyboardAccessAgent.plist
com.apple.LinkedNotesUIService.plist
com.apple.LocalAuthentication.UIAgent.plist
com.apple.MENotificationAgent.plist
com.apple.MTLAssetUpgraderD.plist
com.apple.ManagedClientAgent.agent.plist
com.apple.ManagedClientAgent.enrollagent.plist
com.apple.ManagedSettingsAgent.plist
com.apple.Maps.mapssyncd.plist
com.apple.Maps.pushdaemon.plist
com.apple.MemorySlotNotification.plist
com.apple.MobileAccessoryUpdater.fudHelperAgent.plist
com.apple.ModelCatalogAgent.plist
com.apple.NVMeAgent.plist
com.apple.NowPlayingTouchUI.plist
com.apple.OSDUIHelper.plist
com.apple.PIPAgent.plist
com.apple.PackageUIKit.InstallStatus.plist
com.apple.RapportUIAgent.plist
com.apple.RemoteDesktop.plist
com.apple.RemoteManagementAgent.plist
com.apple.ReportCrash.plist
com.apple.ReportGPURestart.plist
...
com.apple.sidecar-hid-relay.plist
com.apple.sidecar-relay.plist
com.apple.siriactionsd.plist
com.apple.siriinferenced.plist
com.apple.siriknowledged.plist
com.apple.sirittsd.plist
com.apple.sociallayerd.plist
com.apple.speech.speechdatainstallerd.plist
com.apple.speech.speechsynthesisd.arm64.plist
com.apple.speech.speechsynthesisd.x86_64.plist
com.apple.speech.synthesisserver.plist
com.apple.spindump_agent.plist
com.apple.sportsd.plist
com.apple.spotlightknowledged.importer.plist
com.apple.spotlightknowledged.plist
com.apple.spotlightknowledged.updater.plist
com.apple.stickersd.plist
com.apple.storeaccountd.plist
com.apple.storeassetd.plist
com.apple.storedownloadd.plist
com.apple.storekitagent.plist
com.apple.storelegacy.plist
com.apple.storeuid.plist
com.apple.suggestd.plist
com.apple.swcd.plist
com.apple.swtransparencyd.plist
com.apple.symptomsd-diag.plist
com.apple.symptomsd.distributed-agent.plist
com.apple.synapse.contentlinkingd.plist
com.apple.syncdefaultsd.plist
com.apple.syncservices.SyncServer.plist
com.apple.syncservices.uihandler.plist
com.apple.sysdiagnose_agent.plist
com.apple.systemprofiler.plist
com.apple.systemsettingsagent.plist
com.apple.talagent.plist
com.apple.tccd.plist
com.apple.telephonyutilities.callservicesd.plist
com.apple.testmanagerd.plist
com.apple.textcomposerd.plist
com.apple.textunderstandingd.plist
com.apple.thermaltrap.plist
com.apple.timezoneupdates.tznotify.plist
com.apple.tipsd.plist
com.apple.translationd.plist
com.apple.transparencyStaticKey.plist
com.apple.transparencyd.plist
com.apple.triald.plist
com.apple.trustd.agent.plist
com.apple.uarppersonalizationd.plist
com.apple.uikitsystemapp.plist
com.apple.universalaccessAuthWarn.plist
com.apple.universalaccesscontrol.plist
com.apple.universalaccessd.plist
com.apple.unmountassistant.useragent.plist
com.apple.usbnotificationagent.plist
com.apple.usermanagerhelper.plist
com.apple.usernoted.plist
com.apple.usernotificationsd.plist
com.apple.videosubscriptionsd.plist
com.apple.voicebankingd.plist
com.apple.voicememod.plist
com.apple.wallpaper.plist
com.apple.warmd_agent.plist
com.apple.watchlistd.plist
com.apple.weatherd.plist
com.apple.webinspectord.plist
com.apple.webkit.webpushd.plist
com.apple.webprivacyd.plist
com.apple.wifi.WiFiAgent.plist
com.apple.xpc.loginitemregisterd.plist
com.apple.xpc.otherbsd.plist
com.openssh.ssh-agent.plist
(base) miraladutska@Noutbuk-Mira ~ % 

```

## **Observations**

* **Number of running services:** `launchctl list` shows a large number of loaded services (macOS runs many background agents/daemons by default). Many entries have `PID` as `-`, meaning they are loaded but not currently running.
* **Any third-party services:** Yes, there are non-Apple services visible, e.g.:

  * `us.zoom.updater`
  * `com.microsoft.update.agent`
  * `com.google.GoogleUpdater.wake`
  * `application.com.microsoft.Word...`
  * `application.com.microsoft.VSCode...`
  * `application.com.figma.agent...`
* **System vs user agents:** The majority are Apple system services labeled `com.apple.*` (system components). User/third-party apps appear as `application.*` or vendor labels (Zoom/Microsoft/Google). The presence of both LaunchDaemons (system-wide) and LaunchAgents (per-user / UI-related) indicates typical macOS service separation.

---

## 1.4 User Sessions
```
(base) miraladutska@Noutbuk-Mira ~ % who
miraladutska     console      Jan 30 00:11 
miraladutska     ttys000      Feb 17 19:35 
(base) miraladutska@Noutbuk-Mira ~ % last -n 5

miraladutska ttys000                         Tue Feb 17 19:35   still logged in
miraladutska ttys000                         Thu Feb 12 16:42 - 16:42  (00:00)
miraladutska ttys011                         Sun Feb  1 23:20 - 23:20  (00:00)
miraladutska ttys006                         Sun Feb  1 22:23 - 22:23  (00:00)
miraladutska console                         Fri Jan 30 00:11   still logged in
(base) miraladutska@Noutbuk-Mira ~ % last | head -n 5

miraladutska ttys000                         Tue Feb 17 19:35   still logged in
miraladutska ttys000                         Thu Feb 12 16:42 - 16:42  (00:00)
miraladutska ttys011                         Sun Feb  1 23:20 - 23:20  (00:00)
miraladutska ttys006                         Sun Feb  1 22:23 - 22:23  (00:00)
miraladutska console                         Fri Jan 30 00:11   still logged in
(base) miraladutska@Noutbuk-Mira ~ % 
```

## **Observations**

* **Active users:** `miraladutska` is currently logged in on two sessions: the main **console** session and a terminal session **ttys000**.
* **Recent logins:** The most recent login is **Tue Feb 17 19:35** on `ttys000` (active). The console session has been active since **Fri Jan 30 00:11**, consistent with the long system uptime.
* **Any suspicious sessions:** No suspicious logins are visible. All recent sessions belong to the same user account (`miraladutska`) and look consistent with normal local usage.


---

## 1.5 Memory Analysis

```
(base) miraladutska@Noutbuk-Mira ~ % vm_stat

Mach Virtual Memory Statistics: (page size of 16384 bytes)
Pages free:                                9926.
Pages active:                             81196.
Pages inactive:                           73990.
Pages speculative:                         9558.
Pages throttled:                              0.
Pages wired down:                        135317.
Pages purgeable:                           5767.
"Translation faults":                2741171659.
Pages copy-on-write:                   33545501.
Pages zero filled:                   1339922968.
Pages reactivated:                    685460872.
Pages purged:                         273467569.
File-backed pages:                        64165.
Anonymous pages:                         100579.
Pages stored in compressor:             1485412.
Pages occupied by compressor:            175907.
Decompressions:                       758560041.
Compressions:                         873551238.
Pageins:                              127857880.
Pageouts:                               3518087.
Swapins:                               20555316.
Swapouts:                              22549618.
(base) miraladutska@Noutbuk-Mira ~ % top -l 1 | grep PhysMem

PhysMem: 7491M used (2423M wired, 2640M compressor), 100M unused.
(base) miraladutska@Noutbuk-Mira ~ % sysctl hw.memsize

hw.memsize: 8589934592
(base) miraladutska@Noutbuk-Mira ~ % 
```

## **Observations**

* **Total RAM:** The system has **8 GB (8589934592 bytes)** of physical memory installed.

* **Used vs free:**
  Approximately **7491 MB is used**, and only **100 MB is unused**, indicating very high memory utilization.

* **Swap usage:**
  Swap activity is significant:

  * **Swapins:** 20,555,316
  * **Swapouts:** 22,549,618
    This indicates that the system has been actively using swap space.

* **Memory pressure patterns:**

  * A large portion of memory is **wired (2423 MB)**, meaning it cannot be compressed or swapped out.
  * **2640 MB is in compressed memory**, which indicates macOS is actively compressing RAM to avoid excessive swapping.
  * High compression + significant swap activity suggests sustained memory pressure.
  * Only 100 MB free RAM indicates the system is operating near memory capacity.


# Task 2

# **2.1 Network Path Tracing**

---

## **Traceroute Execution**

### Command:

```bash
traceroute github.com
```

### Output:

```text
traceroute to github.com (198.18.0.227), 64 hops max, 40 byte packets
 1  * * *
 2  * * *
 3  * * *
 4  * * *
 5  * *^C
```

### Insight:

* All hops returned `* * *`, meaning no ICMP responses were received.
* This suggests that ICMP packets are being blocked by a firewall, NAT device, or VPN.
* The resolved IP address `198.18.0.227` is unusual and belongs to a testing/reserved IP range, indicating possible DNS interception or traffic filtering.

---

## **DNS Resolution Check**

### Command:

```bash
dig github.com
```

### Output:

```text
;; ->>HEADER<<- opcode: QUERY, status: NOERROR
;; WARNING: recursion requested but not available

;; QUESTION SECTION:
;github.com.			IN	A

;; ANSWER SECTION:
github.com.		1	IN	A	198.18.0.227

;; SERVER: 1.1.1.1#53(1.1.1.1)
```

### Insight:

* DNS successfully resolved `github.com`.
* The returned IP `198.18.0.227` does NOT match GitHub’s real public IP range.
* This strongly suggests DNS redirection or a controlled network environment (possibly lab sandboxing, firewall filtering, or proxying).
* Warning: *“recursion requested but not available”* indicates limited DNS server functionality.

---

# **2.2 Packet Capture**

---

## **Capture DNS Traffic**

### Command:

```bash
sudo tcpdump -c 5 -i any 'port 53' -nn
```

### Output:

```text
20:23:02.905569 IP 240.0.0.2.61183 > 1.0.0.1.53: 49131+ PTR? lb._dns-sd._udp.0.0.0.240.in-addr.arpa.
20:23:02.905892 IP 240.0.0.2.55461 > 1.0.0.1.53: 61064+ PTR? lb._dns-sd._udp.0.16.240.10.in-addr.arpa.
20:23:07.765447 IP 240.0.0.2.53373 > 1.0.0.1.53: 48908+ A? telemetry.individual.githubcopilot.com.
20:23:07.765663 IP 1.0.0.1.53 > 240.0.0.2.53373: 48908- 1/0/0 A 198.18.1.202
20:23:08.884329 IP 240.0.0.2.61183 > 1.0.0.1.53: 49131+ PTR? lb._dns-sd._udp.0.0.0.240.in-addr.arpa.
```

---

## **DNS Query Analysis**

* DNS traffic is sent to `1.0.0.1` (Cloudflare DNS).
* The local IP `240.0.0.2` is highly unusual (240.0.0.0/4 is reserved), indicating a virtualized or sandboxed network environment.
* One example DNS query observed:

```text
A? telemetry.individual.githubcopilot.com.
```

* The response returned IP `198.18.1.202`, again within a reserved range.
* This further confirms DNS redirection or network isolation.

---

# **2.3 Reverse DNS Lookups**

---

## **PTR Lookup for 8.8.4.4**

### Command:

```bash
dig -x 8.8.4.4
```

### Output:

```text
;; no servers could be reached
```

---

## **PTR Lookup for 1.1.2.2**

### Command:

```bash
dig -x 1.1.2.2
```

### Output:

```text
;; no servers could be reached
```

---

## **Comparison of Reverse Lookups**

* Both reverse lookups failed due to DNS server timeouts.
* The errors show communication attempts to `1.1.1.1` and `1.0.0.1`, which did not respond.
* This suggests:

  * Firewall restrictions,
  * DNS filtering,
  * or restricted outbound network access.

Under normal conditions:

* `8.8.4.4` resolves to a Google DNS PTR hostname.
* `1.1.2.2` resolves to a Cloudflare-related hostname.

In this environment, reverse DNS queries are blocked.

---

## **Overall Network Insights**

* Traceroute is fully blocked (likely ICMP filtering).
* DNS resolution works but returns reserved IP ranges (198.18.x.x).
* Packet capture shows DNS queries being redirected.
* Reverse DNS queries fail entirely.
* The network appears to be sandboxed, filtered, or operating behind a strict firewall/VPN.
