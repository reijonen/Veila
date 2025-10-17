import SwiftUI
import SwiftData

struct PlaylistView: View {
	@Binding var currentPlaylistID: UUID?
	@Binding var currentVideoID: String
	@Binding var selection: SidebarSelection

	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Playlist.title) private var playlists: [Playlist]

    var body: some View {
		Group {
			if let playlistID = currentPlaylistID,
			   let playlist = playlists.first(where: { $0.id == playlistID }) {
				Text(playlist.title)

				ForEach(playlist.videos) { video in
					VideoRow(video: video, currentVideoID: $currentVideoID, selection: $selection)
				}
			} else {
				Text("Playlist not found")
					.foregroundColor(.gray)
			}
		}
	}
}
