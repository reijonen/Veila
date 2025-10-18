import SwiftUI
import SwiftData

struct ContentView: View {
	@State private var selection: SidebarSelection = .subscriptions

	@State private var isSearching: Bool = false
	@State private var searchResults: [VideoDTO] = []

	@State private var currentChannelID: String = ""
	@State private var currentVideoID: String = ""
	@State private var currentPlaylistID: UUID? = nil

	var body: some View {
		NavigationSplitView {
			SidebarView(selection: $selection, currentChannelID: $currentChannelID, currentPlaylistID: $currentPlaylistID)
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
				SubscriptionsOverviewView()
			case .search:
				SearchView(isSearching: $isSearching, searchResults: $searchResults, selection: $selection, currentVideoID: $currentVideoID, currentChannelID: $currentChannelID)
			case .playlistOverview:
				PlaylistOverviewView(selection: $selection, currentPlaylistID: $currentPlaylistID)
			case .history:
				HistoryView()
			case .channel:
				ChannelView(currentChannelID: $currentChannelID, currentVideoID: $currentVideoID, selection: $selection)
					.id(currentChannelID)
			case .playlist:
				PlaylistView(currentPlaylistID: $currentPlaylistID, currentVideoID: $currentVideoID, selection: $selection)
			case .watchVideo:
				WatchVideoView(videoID: $currentVideoID)
		}
	}
}
