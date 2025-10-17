import Foundation
import SwiftData

@Model
class Settings {
	var subscriptionsExpanded: Bool = false
	var playlistsExpanded: Bool = false
	var skipSponsorSegments: Bool = true
	var defaultPlaylistID: UUID? = nil

	init() {}
}
