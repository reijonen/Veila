import Foundation
import SwiftData

struct ChannelDTO: Codable, Identifiable, Hashable {
	let id: String
	let title: String
	let desc: String
	let subscribers: UInt
	let videos: Array<VideoDTO>
	let avatarURL: URL
	let bannerURL: URL

	enum CodingKeys: String, CodingKey {
		case id
		case title
		case desc
		case subscribers
		case videos
		case avatarURL = "avatar_url"
		case bannerURL = "banner_url"
	}
}
