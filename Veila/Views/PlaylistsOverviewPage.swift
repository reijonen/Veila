import SwiftUI
import SwiftData

struct PlaylistOverviewView: View {
	@Binding var selection: SidebarSelection
	@Binding var currentPlaylistID: UUID?

	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Playlist.title) private var playlists: [Playlist]

	var body: some View {
		Group {
			ForEach(playlists) { playlist in
				Button(action: {
					self.currentPlaylistID = playlist.id
					self.selection = SidebarSelection.playlist
				}) {
					Text(playlist.title)
//					NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
//						Text(playlist.title)
//					}
				}
			}
		}
	}
}
