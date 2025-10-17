import SwiftUI
import SwiftData

enum SidebarSelection: Hashable {
    case subscriptions
	case channel
	case search
	case playlistOverview
    case playlist
    case history
	case watchVideo
}

struct SidebarView: View {
	@State private var subscriptionsExpanded: Bool = false
	@State private var playlistsExpanded: Bool = false

	@Binding var selection: SidebarSelection
	@Binding var currentChannelID: String
	@Binding var currentPlaylistID: UUID?

    var body: some View {
        List(selection: $selection) {
            DisclosureGroup(isExpanded: $subscriptionsExpanded) {
				SubscriptionsList(selection: $selection, currentChannelID: $currentChannelID)
            } label: {
	//			TODO: what does NavigationLink do? history stack?
                NavigationLink(value: SidebarSelection.subscriptions) {
                    Label("Subscriptions", systemImage: "tray.full")
                }
            }

			DisclosureGroup(isExpanded: $playlistsExpanded) {
				PlaylistList(selection: $selection, currentPlaylistID: $currentPlaylistID)
			} label: {
				NavigationLink(value: SidebarSelection.playlistOverview) {
					Label("Playlists", systemImage: "music.note.list")
				}
			}

			NavigationLink(value: SidebarSelection.history) {
				Label("History", systemImage: "clock.arrow.circlepath")
			}
        }
        .listStyle(.sidebar)
    }
}
