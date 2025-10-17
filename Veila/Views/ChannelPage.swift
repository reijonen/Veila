import SwiftUI
import SwiftData
import Kingfisher

struct ChannelView: View {
	@Binding var currentChannelID: String
	@Binding var currentVideoID: String
	@Binding var selection: SidebarSelection

	@State private var channel: Channel? = nil
	@State private var isLoading: Bool = true
	@State private var errorMessage: String? = nil

	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Subscription.title) var subscriptions: [Subscription]

	private func formatSubCount(_ number: UInt) -> String {
		if number < 1_000 {
			return "\(number)"
		} else if number < 1_000_000 {
			let divided = Double(number) / 1_000
			let formatted = divided.truncatingRemainder(dividingBy: 1) == 0 ?
			String(format: "%.0f", divided) :
			String(format: "%.1f", divided)
			return "\(formatted)k"
		} else {
			let divided = Double(number) / 1_000_000
			let formatted = divided.truncatingRemainder(dividingBy: 1) == 0 ?
			String(format: "%.0f", divided) :
			String(format: "%.1f", divided)
			return "\(formatted)M"
		}
	}

	func toggleSubscription() {
		if let sub = subscriptions.first(where: { $0.id == currentChannelID }) {
			modelContext.delete(sub)
		} else if let channel = channel {
			let newSub = Subscription(
				id: currentChannelID,
				title: channel.title,
				url: URL(string: "https://www.youtube.com/feeds/videos.xml?channel_id=\(currentChannelID)")!
			)
			modelContext.insert(newSub)
		}
		try? modelContext.save()
	}

	private var subscriptionButton: some View {
		let isSubscribed = subscriptions.contains(where: { $0.id == currentChannelID })
		return Button(action: toggleSubscription) {
			Text(isSubscribed ? "Unsubscribe" : "Subscribe")
				.font(.subheadline)
				.padding(6)
				.background(isSubscribed ? Color.gray : Color.blue)
				.foregroundColor(.white)
				.cornerRadius(4)
		}
		.buttonStyle(PlainButtonStyle())
	}

	var body: some View {
		Group {
			if let channel = channel {
				ScrollView {
					VStack(spacing: 16) {
						KFImage(channel.bannerURL)
							.resizable()
							.scaledToFill()
							.frame(height: 200)
							.clipped()
							.background(Color.gray.frame(height: 200))

						HStack(alignment: .center, spacing: 16) {
							KFImage(channel.avatarURL)
								.resizable()
								.frame(width: 80, height: 80)
								.clipShape(Circle())
								.background(Circle().fill(Color.gray).frame(width: 80, height: 80))

							HStack {
								VStack(alignment: .leading) {
									Text(channel.title)
										.font(.title2)
										.bold()

									Text("\(self.formatSubCount(channel.subscribers)) subscribers")
										.font(.subheadline)
										.foregroundColor(.secondary)

									Text(channel.desc)
										.font(.body)
										.foregroundColor(.secondary)
										.lineLimit(3)
								}

								subscriptionButton
							}
						}
						.padding(.horizontal)

						Divider()

						VStack(alignment: .leading, spacing: 12) {
							Text("Videos")
								.font(.headline)
								.padding(.horizontal)

							ForEach(channel.videos) { video in
								VideoRow(video: video, currentVideoID: $currentVideoID, selection: $selection)
									.padding(.horizontal)
							}
						}
					}
				}
			} else if isLoading {
				ProgressView("Loading channel...")
					.frame(maxWidth: .infinity, maxHeight: .infinity)
			} else if let errorMessage = errorMessage {
				Text("Error: \(errorMessage)")
					.foregroundColor(.red)
					.multilineTextAlignment(.center)
			}
		}
		.task(id: currentChannelID) {
			await fetchChannel()
		}
		.onChange(of: channel) { newChannel in
			if let ch = newChannel {
				print("Channel updated: \(ch.title) (ID: \(ch.id))")
			}
		}
	}

	private func fetchChannel() async {
		do {
			channel = try await ContentService.shared.getChannel(id: currentChannelID)
		} catch {
			errorMessage = error.localizedDescription
		}
		isLoading = false
	}
}

struct AddToPlaylistButton: View {
	let video: Video
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Playlist.title) private var playlists: [Playlist]

	@State private var showCreateNew: Bool = false
	@State private var newPlaylistName: String = ""
	@State private var showPickerPopover: Bool = false
	@State private var popoverAnchorID = UUID()
	@State private var isCreatingInline: Bool = false

	@ViewBuilder
	private func playlistPickerContent() -> some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				if isCreatingInline {
					Button(action: { withAnimation { isCreatingInline = false } }) {
						Image(systemName: "chevron.left")
					}
					.buttonStyle(.plain)
				}
				Text(isCreatingInline ? "Create Playlist" : "Add to Playlist")
					.font(.headline)
				Spacer()
			}
			Divider()

			if isCreatingInline {
				VStack(alignment: .leading, spacing: 8) {
					TextField("Playlist Name", text: $newPlaylistName)
						.textFieldStyle(.roundedBorder)
					HStack {
						Button("Cancel") {
							withAnimation {
								isCreatingInline = false
								newPlaylistName = ""
							}
						}
						Spacer()
						Button("Create") {
							createPlaylistAndAdd()
							// Close popover after creation
							showPickerPopover = false
							isCreatingInline = false
							newPlaylistName = ""
						}
						.keyboardShortcut(.defaultAction)
						.disabled(newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
					}
				}
				.padding(.vertical, 4)
			} else {
				if playlists.isEmpty {
					Text("No playlists yet").foregroundStyle(.secondary)
				} else {
					ScrollView {
						VStack(alignment: .leading, spacing: 4) {
							ForEach(playlists) { playlist in
								Button(action: {
									addToPlaylist(playlist)
									showPickerPopover = false
								}) {
									HStack {
										Image(systemName: "folder")
										Text(playlist.title)
										Spacer()
									}
									.padding(6)
								}
								.buttonStyle(.plain)
								.background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .controlAccentColor).opacity(0.08)).opacity(0))
							}
						}
						.padding(.vertical, 4)
					}
					.frame(maxHeight: 220)
				}
				Divider()
				HStack {
					Button("Create New Playlist") {
						withAnimation { isCreatingInline = true }
					}
					Spacer()
				}
			}
		}
		.padding(12)
		.frame(minWidth: 280)
	}

	var body: some View {
		HStack(spacing: 0) {
			// Unified segmented container
			HStack(spacing: 0) {
				// Left segment: Save (default or picker)
				Button(action: {
					// Try default; if none, open picker
					do {
						if let defaultPlaylistID = try Settings.shared(context: modelContext).defaultPlaylistID,
						   let playlist = playlists.first(where: { $0.id == defaultPlaylistID }) {
							addToPlaylist(playlist)
						} else {
							showPickerPopover = true
						}
					} catch {
						showPickerPopover = true
					}
				}) {
					HStack(spacing: 6) {
						Image(systemName: "tray.and.arrow.down")
						Text("Save")
					}
					.frame(height: 28)
					.padding(.horizontal, 10)
					.contentShape(Rectangle())
				}
				.buttonStyle(.plain)
				.background(Color.blue)
				.foregroundColor(.white)

				// Right segment: always open picker
				Button(action: {
					showPickerPopover = true
				}) {
					Image(systemName: "chevron.down")
						.frame(width: 30, height: 28)
						.contentShape(Rectangle())
				}
				.buttonStyle(.plain)
				.background(Color.blue.opacity(0.95))
				.foregroundColor(.white)
			}
			.clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
			.overlay(
				RoundedRectangle(cornerRadius: 6, style: .continuous)
					.stroke(Color.blue.opacity(0.9), lineWidth: 0)
			)
			.id(popoverAnchorID) // stable anchor for popover
		}
		.popover(isPresented: $showPickerPopover, arrowEdge: .bottom) {
			playlistPickerContent()
		}
	}

	private func addToDefault() {
		do {
			if let defaultPlaylistID = try Settings.shared(context: modelContext).defaultPlaylistID,
			   let playlist = playlists.first(where: { $0.id == defaultPlaylistID }) {
				addToPlaylist(playlist)
			} else {
				showPickerPopover = true
			}
		} catch {
			showPickerPopover = true
		}
	}

	private func addToPlaylist(_ playlist: Playlist) {
		if !playlist.videos.contains(video) {
			playlist.videos.append(video)
			try? modelContext.save()
		}
	}

	private func createPlaylistAndAdd() {
		let playlist = Playlist(title: newPlaylistName)
		playlist.videos.append(video)
		modelContext.insert(playlist)
		try? modelContext.save()
	}
}

