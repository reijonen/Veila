import SwiftUI
import SwiftData

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
			if isLoading {
				ProgressView("Loading channel...")
					.frame(maxWidth: .infinity, maxHeight: .infinity)
			} else if let channel = channel {
				ScrollView {
					VStack(spacing: 16) {
						AsyncImage(url: channel.bannerURL) { image in
							image
								.resizable()
								.scaledToFill()
								.frame(height: 200)
								.clipped()
						} placeholder: {
							Color.gray.frame(height: 200)
						}

						HStack(alignment: .center, spacing: 16) {
							AsyncImage(url: channel.avatarURL) { image in
								image
									.resizable()
									.frame(width: 80, height: 80)
									.clipShape(Circle())
							} placeholder: {
								Circle().fill(Color.gray).frame(width: 80, height: 80)
							}

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
			} else if let errorMessage = errorMessage {
				Text("Error: \(errorMessage)")
					.foregroundColor(.red)
					.multilineTextAlignment(.center)
			}
		}
		.task() {
			await fetchChannel()
		}
	}

	private func fetchChannel() async {
		do {
			channel = try await ContentService.shared.getChannel(id: currentChannelID)
			print("Channel:", channel!)
		} catch {
			print("ERROR:", error)
			errorMessage = error.localizedDescription
		}
		isLoading = false
	}
}

struct VideoRow: View {
	let video: Video
	@Binding var currentVideoID: String
	@Binding var selection: SidebarSelection

	var body: some View {
		HStack(spacing: 12) {
			Button(action: {
				selection = .watchVideo
				currentVideoID = video.id
			}) {
				AsyncImage(url: video.thumbnail) { image in
					image
						.resizable()
						.scaledToFill()
						.frame(width: 120, height: 68)
						.clipped()
						.cornerRadius(6)
				} placeholder: {
					Color.gray.frame(width: 120, height: 68)
				}
			}
			.buttonStyle(PlainButtonStyle())

			VStack(alignment: .leading, spacing: 4) {
				Button(action: {
					selection = .watchVideo
					currentVideoID = video.id
				}) {
					Text(video.title)
						.font(.subheadline)
						.bold()
						.lineLimit(2)
				}
				.buttonStyle(PlainButtonStyle())

				HStack {
//					Text(video.uploader)
//						.font(.caption)
//						.foregroundColor(.secondary)
					if video.isLive {
						Text("LIVE")
							.font(.caption2)
							.bold()
							.foregroundColor(.red)
							.padding(4)
							.background(Color.red.opacity(0.2))
							.cornerRadius(4)
					}
				}
				Text("\(formatViews(video.views)) views" + (video.duration != nil ? " • \(formatDuration(video.duration!))" : ""))
					.font(.caption2)
					.foregroundColor(.secondary)
			}
		}
	}

	private func formatViews(_ number: UInt) -> String {
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

	private func formatDuration(_ seconds: Double) -> String {
		let hrs = Int(seconds) / 3600
		let mins = (Int(seconds) % 3600) / 60
		let secs = Int(seconds) % 60
		if hrs > 0 {
			return String(format: "%d:%02d:%02d", hrs, mins, secs)
		} else {
			return String(format: "%d:%02d", mins, secs)
		}
	}
}
