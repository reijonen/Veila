import Foundation
import SwiftData

@Model
class Playlist: Identifiable {
	@Attribute(.unique) var id: UUID
	var saveLocallyByDefault: Bool
	var title: String
	var videos: [Video]

	init(title: String) {
		self.id = UUID()
		self.saveLocallyByDefault = false
		self.title = title
		self.videos = []
	}
}
