import Foundation
import SwiftData

@Model
class HistoryItem: Identifiable {
	@Attribute(.unique) var id: UUID
	var date: Date
	var duration: Double
	var video: Video

	init(video: Video) {
		self.id = UUID()
		self.date = Date()
		self.duration = 0.0
		self.video = video
	}
}
