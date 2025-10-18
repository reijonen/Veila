import SwiftUI
import SwiftData

struct VideoRowView: View {
	let video: VideoDTO

	@Binding var selection: SidebarSelection
	@Binding var currentChannelID: String

	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Subscription.title) var subscriptions: [Subscription]

	var body: some View {
		HStack(alignment: .top, spacing: 12) {
			AsyncImage(url: video.thumbnail) { phase in
				switch phase {
					case .empty:
						Color.gray.opacity(0.3)
							.frame(width: 120, height: 68)
							.cornerRadius(8)
					case .success(let image):
						image
							.resizable()
							.scaledToFill()
							.frame(width: 120, height: 68)
							.clipped()
							.cornerRadius(8)
					case .failure(_):
						Color.red.opacity(0.3)
							.frame(width: 120, height: 68)
							.cornerRadius(8)
					@unknown default:
						EmptyView()
				}
			}

			VStack(alignment: .leading, spacing: 4) {
				Text(video.title)
					.font(.headline)
					.lineLimit(2)

				Button(action: {
					selection = .channel
					currentChannelID = video.channelID
				}) {
					Text(video.uploader)
						.font(.subheadline)
						.foregroundColor(.blue)
				}
				.buttonStyle(PlainButtonStyle())

				Button(action: {
					if !subscriptions.contains(where: { $0.id == video.channelID }) {
						let newSub = Subscription(
							id: video.channelID,
							title: video.uploader,
							url: URL(string: "https://www.youtube.com/feeds/videos.xml?channel_id=\(video.channelID)")!
						)
						modelContext.insert(newSub)
						try? modelContext.save()
					}
				}) {
					Text("Subscribe")
						.font(.subheadline)
						.padding(6)
						.background(Color.blue)
						.foregroundColor(.white)
						.cornerRadius(4)
				}
				.buttonStyle(PlainButtonStyle())

				HStack(spacing: 8) {
					Text("\(video.views.formatted()) views")
						.font(.caption)
						.foregroundColor(.secondary)

					if video.isLive {
						Text("Live")
							.font(.caption)
							.foregroundColor(.red)
					} else {
						Text(formatDuration(video.duration!))
							.font(.caption)
							.foregroundColor(.secondary)
					}
				}
			}
		}
		.padding(.vertical, 6)
	}

	private func formatDuration(_ seconds: Double) -> String {
		let hours = Int(seconds / 3600)
		let mins  = Int(seconds.truncatingRemainder(dividingBy: 3600) / 60)
		let secs  = Int(seconds.truncatingRemainder(dividingBy: 60))

		if hours > 0 {
			return String(format: "%d:%02d:%02d", hours, mins, secs)
		} else {
			return String(format: "%d:%02d", mins, secs)
		}
	}
}


struct SearchView: View {
	@Binding var isSearching: Bool
	@Binding var searchResults: [VideoDTO]
	@Binding var selection: SidebarSelection
	@Binding var currentVideoID: String
	@Binding var currentChannelID: String
	
	var body: some View {
		Group {
			if isSearching {
				VStack(spacing: 16) {
					ProgressView()
					Text("Searching...")
						.font(.headline)
						.foregroundColor(.gray)
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
			} else if searchResults.isEmpty {
				VStack(spacing: 16) {
					Text("No results found")
						.font(.headline)
						.foregroundColor(.gray)
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
			} else {
				List(searchResults, id: \.id) { video in
					Button(action: {
						selection = .watchVideo
						currentVideoID = video.id
					}) {
						VideoRowView(video: video, selection: $selection, currentChannelID: $currentChannelID)

//						VideoRow(video: video, selection: $selection, currentChannelID: $currentChannelID)
					}
					.buttonStyle(PlainButtonStyle())
				}
				.listStyle(PlainListStyle())
			}
		}
	}
}
