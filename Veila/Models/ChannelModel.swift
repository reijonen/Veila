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

	init(id: String, title: String, desc: String, subscribers: UInt, videos: Array<Video>, avatarURL: URL, bannerURL: URL) {
		self.id = id
		self.title = title
		self.desc = desc
		self.subscribers = subscribers
		self.videos = videos
		self.avatarURL = avatarURL
		self.bannerURL = bannerURL
	}
}
