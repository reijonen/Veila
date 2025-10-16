import Foundation
import SwiftData

struct Channel: Codable, Identifiable, Hashable {
    let id: String
	let title: String
	let desc: String
	let subscribers: UInt
	let videos: Array<Video>
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
