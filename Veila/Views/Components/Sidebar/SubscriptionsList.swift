import SwiftUI
import SwiftData

struct SubscriptionsList: View {
	@Binding var selection: SidebarSelection
	@Binding var currentChannelID: String
	
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Subscription.title) var subscriptions: [Subscription]
	
	var body: some View {
		ForEach(subscriptions) { channel in
			Button(action: {
				selection = .channel
				currentChannelID = channel.id
			}) {
				Text(channel.title)
			}
			.buttonStyle(PlainButtonStyle())
		}
	}
}
