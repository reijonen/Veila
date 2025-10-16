import Foundation
import SwiftData

@Model
class Subscription: Identifiable {
	@Attribute(.unique) var id: String
	var title: String
	var url: URL

	init(id: String, title: String, url: URL) {
		self.id = id
		self.title = title
		self.url = url
	}
}
