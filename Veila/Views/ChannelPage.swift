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

	@State private var isFetchingNewData = false
	@State private var lastChannel: Channel? = nil

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
			if let channel = isFetchingNewData ? lastChannel : channel {
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

						// Videos list
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
			} else if isFetchingNewData || isLoading {
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
		isFetchingNewData = true
		lastChannel = channel // keep old data
		do {
			let newChannel = try await ContentService.shared.getChannel(id: currentChannelID)
			channel = newChannel
		} catch {
			errorMessage = error.localizedDescription
		}
		isFetchingNewData = false
		isLoading = false
	}
}

struct AddToPlaylistButton: View {
	let video: Video
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Playlist.title) private var playlists: [Playlist]

	@State private var showPlaylistMenu: Bool = false
	@State private var showCreateNew: Bool = false
	@State private var newPlaylistName: String = ""

	var body: some View {
		HStack(spacing: 0) {
			// Main "Add to Playlist" button
			Button(action: addToDefault) {
				Label("Add to Playlist", systemImage: "plus")
					.padding(.vertical, 6)
					.padding(.horizontal, 12)
					.background(Color.blue)
					.foregroundColor(.white)
//					.cornerRadius(4, corners: [.topLeft, .bottomLeft])
			}

			// Menu button (dots)
			Menu {
				ForEach(playlists) { playlist in
					Button(playlist.title) {
						addToPlaylist(playlist)
					}
				}
				Divider()
				Button("Create New Playlist") {
					showCreateNew = true
				}
			} label: {
				Image(systemName: "ellipsis")
					.padding(.vertical, 6)
					.padding(.horizontal, 8)
					.background(Color.blue)
					.foregroundColor(.white)
			}
//			.cornerRadius(4, corners: [.topRight, .bottomRight])
		}
		.sheet(isPresented: $showCreateNew) {
			VStack {
				Text("Create New Playlist")
					.font(.headline)
				TextField("Playlist Name", text: $newPlaylistName)
					.textFieldStyle(.roundedBorder)
					.padding()
				Button("Create") {
					createPlaylistAndAdd()
					showCreateNew = false
					newPlaylistName = ""
				}
				.padding()
				Button("Cancel") {
					showCreateNew = false
					newPlaylistName = ""
				}
			}
			.padding()
		}
	}

	private func addToDefault() {
		do {
			if let defaultPlaylistID = try Settings.shared(context: modelContext).defaultPlaylistID,
			   let playlist = playlists.first(where: { $0.id == defaultPlaylistID }) {
				addToPlaylist(playlist)
			} else {
				// No default: open menu
				showPlaylistMenu = true
			}
		} catch {
			print("Failed to fetch settings: \(error)")
			showPlaylistMenu = true
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

