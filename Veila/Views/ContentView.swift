import SwiftUI
import SwiftData

struct ContentView: View {
	@State private var selection: SidebarSelection = .subscriptions

	@State private var isSearching: Bool = false
	@State private var searchResults: [Video] = []

	@State private var currentChannelID: String = ""

	@State private var currentVideoID: String = ""

	@State private var subscriptions: Array<Subscription> = []

	var body: some View {
		NavigationSplitView {
			SidebarView(selection: $selection, currentChannelID: $currentChannelID, subscriptions: $subscriptions)
		} detail: {
			content
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
				.toolbar {
					ToolbarItemGroup(placement: .principal) {
						SearchBarView(selection: $selection, isSearching: $isSearching, searchResults: $searchResults)
					}
				}
		}
	}

	@ViewBuilder
	private var content: some View {
		switch selection {
			case .subscriptions:
				SubscriptionsView()
			case .channel:
				ChannelView(currentChannelID: $currentChannelID, currentVideoID: $currentVideoID, selection: $selection)
			case .search:
				SearchView(isSearching: $isSearching, searchResults: $searchResults, selection: $selection, currentVideoID: $currentVideoID, currentChannelID: $currentChannelID, subscriptions: $subscriptions)
//			case .playlists:
//				Text("playlists")
//				PlaylistsView()
//			case .history:
//				Text("history")
//				HistoryView()
			case .watchVideo:
				WatchVideoView(videoID: $currentVideoID)
		}
	}
}
