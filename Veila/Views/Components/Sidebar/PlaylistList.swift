import SwiftUI
import SwiftData

struct PlaylistList: View {
	@Binding var selection: SidebarSelection
	@Binding var currentPlaylistID: UUID?

	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Playlist.title) var playlists: [Playlist]

	func getDefaultPlaylistID() -> UUID? {
		try? Settings.shared(context: modelContext).defaultPlaylistID
	}

	var body: some View {
		ForEach(playlists) { playlist in
			Button(action: {
				selection = .playlist
				currentPlaylistID = playlist.id
			}) {
				Text(playlist.title)
				if playlist.id == getDefaultPlaylistID() {
					Text("(default)").foregroundColor(.secondary)
				}
			}
			.buttonStyle(PlainButtonStyle())
			.contextMenu {
				if playlist.id != getDefaultPlaylistID() {
					Button("Make Default") {
						do {
							let settings = try Settings.shared(context: modelContext)
							settings.defaultPlaylistID = playlist.id
							try modelContext.save()
						} catch {
							print("Failed to set default playlist: \(error)")
						}
					}
				} else {
					Button("Undefault") {
						do {
							let settings = try Settings.shared(context: modelContext)
							settings.defaultPlaylistID = nil
							try modelContext.save()
						} catch {
							print("Failed to set default playlist: \(error)")
						}
					}

				}

				Button("Delete Playlist", role: .destructive) {
					withAnimation {
						modelContext.delete(playlist)
					}
				}
			}
		}
	}
}
