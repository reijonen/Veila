import SwiftUI
import Kingfisher

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
				KFImage(video.thumbnail)
					.resizable()
					.scaledToFill()
					.frame(width: 120, height: 68)
					.clipped()
					.background(Color.gray.frame(width: 120, height: 68))
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

			AddToPlaylistButton(video: video)
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
