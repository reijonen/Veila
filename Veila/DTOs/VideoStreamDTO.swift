import SwiftUI

struct VideoStreamDTO: Codable {
	let streamURL: URL

	enum CodingKeys: String, CodingKey {
		case streamURL = "stream_url"
	}
}
