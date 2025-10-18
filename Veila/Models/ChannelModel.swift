import Foundation
import SwiftData

@Model
class Channel {
	var id: String
	var title: String
	var desc: String
	var subscribers: UInt
	var videos: Array<Video>
	var avatarURL: URL
	var bannerURL: URL

	init(dto: ChannelDTO) {
		self.id = dto.id
		self.title = dto.title
		self.desc = dto.desc
		self.subscribers = dto.subscribers
		var videos: [Video] = []
		for videoDTO in dto.videos {
			videos.append(Video(dto: videoDTO))
		}
		self.videos = videos
		self.avatarURL = dto.avatarURL
		self.bannerURL = dto.bannerURL
	}
}
