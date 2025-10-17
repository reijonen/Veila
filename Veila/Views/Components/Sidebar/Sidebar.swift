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
	@Binding var selection: SidebarSelection
	@Binding var currentChannelID: String
	@Binding var currentPlaylistID: UUID?

	@Environment(\.modelContext) private var context
	@Query private var settings: [Settings]

    var body: some View {
		let appSettings = settings.first!

        List(selection: $selection) {
            DisclosureGroup(isExpanded: Binding(
				get: { appSettings.subscriptionsExpanded },
				set: { newValue in
					appSettings.subscriptionsExpanded = newValue
					try? context.save()
				})
			) {
				SubscriptionsList(selection: $selection, currentChannelID: $currentChannelID)
            } label: {
	//			TODO: what does NavigationLink do? history stack?
                NavigationLink(value: SidebarSelection.subscriptions) {
                    Label("Subscriptions", systemImage: "tray.full")
                }
            }

			DisclosureGroup(isExpanded: Binding(
				get: { appSettings.playlistsExpanded },
				set: { newValue in
					appSettings.playlistsExpanded = newValue
					try? context.save()
				})
			) {
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
