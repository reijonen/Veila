import SwiftUI
import SwiftData
import AVKit

struct WatchVideoView: View {
	@Environment(\.modelContext) private var modelContext

	@Binding var videoID: String

	@State private var player: AVPlayer = AVPlayer()
	@State private var isLoading = true
	@State private var skipSegments: [SkipSegmentDTO] = []
	@State private var errorMessage: String? = nil
	@State private var timeObserver: Any?

	@State private var playerObservers: [NSKeyValueObservation] = []
	@State private var itemObservers: [NSObjectProtocol] = []

	@State private var historyItem: HistoryItem? = nil

	@State private var video: Video? = nil

	@State private var lastSave: Date? = nil

	func updateDuration(_ duration: Double) {
		historyItem!.duration = duration
		if Date().timeIntervalSince(lastSave!) > 10 {
			try? modelContext.save()
			lastSave = Date()
		}
	}

	var body: some View {
		ZStack {
			if errorMessage == nil {
				if !isLoading {
					VideoPlayer(player: player)
						.transition(.opacity) // optional fade-in effect
						.animation(.easeInOut, value: isLoading)
				} else {
					Color.black.opacity(0.4)
						.ignoresSafeArea()
					ProgressView()
						.progressViewStyle(CircularProgressViewStyle(tint: .white))
						.foregroundColor(.white)
						.padding()
				}
			} else {
				Text(self.errorMessage!)
			}
		}
		.onAppear {
			Task {
				do {
					let videoDTO = try await ContentService.shared.getVideo(id: videoID)

					self.video = Video(dto: videoDTO)
					self.historyItem = HistoryItem(video: video!)

					modelContext.insert(historyItem!)
					try? modelContext.save()
					lastSave = Date()

					print("Playing video:", self.video!)
					await play()
				} catch VideoError.ageRestricted {
					self.errorMessage = "Video is age-restricted."
				} catch {
					self.errorMessage = error.localizedDescription
				}

				do {
					let segments = try await ContentService.shared.getSkipSegments(id: self.videoID)
					if segments != nil {
						self.skipSegments = segments!
						monitorSkipSegments()
					}
					print("Skip segments:", self.skipSegments)
				} catch {
					print("Failed to extract skip segments for video with ID '\(self.videoID)': \(error).\nProceeding with no skip segments.")
				}

			}
		}
		.onDisappear {
			player.pause()
			player.replaceCurrentItem(with: nil)

//			// Remove periodic observer
			if let observer = timeObserver {
				player.removeTimeObserver(observer)
				timeObserver = nil
			}

			// Remove KVO and Notification observers
			playerObservers.forEach { $0.invalidate() }
			playerObservers.removeAll()
			itemObservers.forEach { NotificationCenter.default.removeObserver($0) }
			itemObservers.removeAll()

		}
	}

	@MainActor
	func monitorSkipSegments() {
		guard !skipSegments.isEmpty else { return }

		let interval = CMTime(seconds: 1, preferredTimescale: 600)
		player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
			updateDuration(time.seconds)

			let currentTime = CMTimeGetSeconds(self.player.currentTime())

			for skip in self.skipSegments {
				let start = skip.segment[0]
				let end = skip.segment[1]

				if currentTime >= start && currentTime < end {
//					TODO: jump only once, set segment done, remove + 2
					self.player.seek(to: CMTime(seconds: end + 2, preferredTimescale: 600)) { _ in
						print("⏩ Skipped segment: \(start) → \(end)")
					}
					break
				}
			}
		}
	}

	func play() async {
		await resilientPlay(url: self.video!.streamURL!, maxRetries: 100)
		self.isLoading = false
	}

	@MainActor
	func resilientPlay(url: URL, maxRetries: Int = 5) async {
		var attempt = 0
		var playbackStarted = false

		func cleanupObservers() {
			playerObservers.forEach { $0.invalidate() }
			playerObservers.removeAll()
			itemObservers.forEach { NotificationCenter.default.removeObserver($0) }
			itemObservers.removeAll()
		}

		func startPlayback() {
			playbackStarted = false
			print("▶️ Starting playback (attempt \(attempt + 1))")

			let item = AVPlayerItem(url: url)
			cleanupObservers() // clean old ones before replacing
			player.automaticallyWaitsToMinimizeStalling = false
			player.replaceCurrentItem(with: item)
			player.play()

			// observe item notifications
			itemObservers.append(NotificationCenter.default.addObserver(
				forName: .AVPlayerItemTimeJumped,
				object: item,
				queue: .main
			) { _ in
				playbackStarted = true
				isLoading = false
				print("✅ Time jumped — playback active")
			})

			itemObservers.append(NotificationCenter.default.addObserver(
				forName: .AVPlayerItemFailedToPlayToEndTime,
				object: item,
				queue: .main
			) { _ in
				print("❌ Failed to play to end time")
			})

			itemObservers.append(NotificationCenter.default.addObserver(
				forName: .AVPlayerItemPlaybackStalled,
				object: item,
				queue: .main
			) { _ in
				print("⚠️ Playback stalled")
			})

			itemObservers.append(NotificationCenter.default.addObserver(
				forName: .AVPlayerItemNewErrorLogEntry,
				object: item,
				queue: .main
			) { _ in
				print("🧾 New error log entry: \(item.errorLog()?.events.last?.errorComment ?? "")")
			})

			// observe player status
			let obs1 = player.observe(\.timeControlStatus, options: [.new]) { player, _ in
				switch player.timeControlStatus {
					case .playing:
						playbackStarted = true
						isLoading = false
						print("🎬 timeControlStatus → playing")
					case .paused:
						print("⏸ timeControlStatus → paused")
					case .waitingToPlayAtSpecifiedRate:
						print("⌛ waitingToPlayAtSpecifiedRate")
					@unknown default:
						break
				}
			}
			playerObservers.append(obs1)
		}

		isLoading = true

		while attempt < maxRetries {
			startPlayback()
			try? await Task.sleep(nanoseconds: 3000_000_000)

			if !playbackStarted {
				print("⏳ No playback start detected — retrying (\(attempt + 1))")
				player.replaceCurrentItem(with: nil)
				attempt += 1
			} else {
				print("✅ Playback confirmed active")
				return
			}
		}

		print("⚠️ Gave up after \(maxRetries) attempts")
		cleanupObservers()
	}
}
