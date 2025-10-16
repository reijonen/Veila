import Foundation

struct Subscription: Codable, Identifiable, Hashable {
	let id: String
	let title: String
	let url: URL

	enum CodingKeys: String, CodingKey {
		case id
		case title
		case url
	}
}
