import Foundation
import SwiftData

@Model
class Video {
	var id: String
	var title: String
	var channelID: String
	var uploader: String
	var duration: Double?
	var views: UInt
	var isLive: Bool
	var thumbnail: URL
	var streamURL: URL?

	init(dto: VideoDTO) {
		self.id = dto.id
		self.title = dto.title
		self.channelID = dto.channelID
		self.uploader = dto.uploader
		self.duration = dto.duration
		self.views = dto.views
		self.isLive = dto.isLive
		self.thumbnail = dto.thumbnail
		self.streamURL = dto.streamURL
	}

}
