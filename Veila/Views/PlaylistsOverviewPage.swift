import SwiftUI
import SwiftData

struct PlaylistOverviewView: View {
	@Binding var selection: SidebarSelection
	@Binding var currentPlaylistID: UUID?

	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Playlist.title) private var playlists: [Playlist]

	var body: some View {
		Group {
			if playlists.count != 0 {
				ForEach(playlists) { playlist in
					Button(action: {
						self.currentPlaylistID = playlist.id
						self.selection = SidebarSelection.playlist
					}) {
						Text(playlist.title)
					}
				}
			} else {
				Text("No playlists yet")
			}
		}
	}
}
