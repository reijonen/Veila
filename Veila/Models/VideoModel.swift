import Foundation

struct Video: Codable, Identifiable, Hashable {
    let id: String
    let title: String
	let channelID: String
	let uploader: String
	let duration: Double?
	let views: UInt
	let isLive: Bool
    let thumbnail: URL
	let streamURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case title
		case channelID = "channel_id"
		case uploader
		case duration
		case views
		case isLive = "is_live"
		case thumbnail
		case streamURL = "stream_url"
    }
}
