import SwiftUI
import SwiftData

enum SidebarSelection: Hashable {
    case subscriptions
	case channel
	case search
//    case playlists
//    case history
	case watchVideo
}

struct SubscriptionsList: View {
	@Binding var selection: SidebarSelection
	@Binding var currentChannelID: String

	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Subscription.title) var subscriptions: [Subscription]

	var body: some View {
		if subscriptions.isEmpty {
			Text("No subscriptions")
				.foregroundStyle(.secondary)
		} else {
			ForEach(subscriptions) { channel in
				Button(action: {
					selection = .channel
					currentChannelID = channel.id
				}) {
					Text(channel.title)
				}
				.buttonStyle(PlainButtonStyle())

	//			TODO: sub deletion
	//			.contextMenu {
	//				Button(role: .destructive) {
	//					deleteChannel(channel)
	//				} label: {
	//					Label("Delete", systemImage: "trash")
	//				}
	//			}
			}
		}
	}

//    private func deleteChannel(_ channel: Channel) {
//        withAnimation {
//            modelContext.delete(channel)
//        }
//    }
}

struct SidebarView: View {
	@State private var subscriptionsExpanded: Bool = true
	@Binding var selection: SidebarSelection
	@Binding var currentChannelID: String

    var body: some View {
        List(selection: $selection) {
            DisclosureGroup(isExpanded: $subscriptionsExpanded) {
				SubscriptionsList(selection: $selection, currentChannelID: $currentChannelID)
            } label: {
                NavigationLink(value: SidebarSelection.subscriptions) {
                    Label("Subscriptions", systemImage: "tray.full")
                }
            }

//			TODO: what does NavigationLink do? history stack?
//            Section {
//                NavigationLink(value: SidebarSelection.playlists) {
//                    Label("Playlists", systemImage: "music.note.list")
//                }
//                NavigationLink(value: SidebarSelection.history) {
//                    Label("History", systemImage: "clock.arrow.circlepath")
//                }
//            }
        }
        .listStyle(.sidebar)
    }
}
