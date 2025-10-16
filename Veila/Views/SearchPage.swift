import SwiftUI

struct VideoRowView: View {
	let video: Video

	@Binding var selection: SidebarSelection
	@Binding var currentChannelID: String
	@Binding var subscriptions: Array<Subscription>

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
					let newSubscription = Subscription(
						id: video.channelID,
						title: video.uploader,
						url: URL(string: "https://www.example.com/channel/\(video.channelID)")! // Replace with actual channel URL
					)

					// Add only if it's not already in the subscriptions
					if !subscriptions.contains(newSubscription) {
						subscriptions.append(newSubscription)
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
	@Binding var searchResults: [Video]
	@Binding var selection: SidebarSelection
	@Binding var currentVideoID: String
	@Binding var currentChannelID: String
	@Binding var subscriptions: Array<Subscription>

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
//					Image(systemName: "magnifyingglass.circle")
//						.resizable()
//						.frame(width: 60, height: 60)
//						.foregroundColor(.gray)
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
						VideoRowView(video: video, selection: $selection, currentChannelID: $currentChannelID, subscriptions: $subscriptions)
					}
					.buttonStyle(PlainButtonStyle())
				}
				.listStyle(PlainListStyle())
			}
		}
	}
}
