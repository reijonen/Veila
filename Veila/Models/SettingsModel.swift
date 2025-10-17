import Foundation
import SwiftData
import Combine

@Model
class Settings {
	var skipSponsorSegments: Bool = true
	var defaultPlaylistID: UUID?

	init() {
		self.skipSponsorSegments = true
		self.defaultPlaylistID = nil
	}
}
