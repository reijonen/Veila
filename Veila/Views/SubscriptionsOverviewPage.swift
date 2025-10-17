import SwiftUI
import SwiftData

struct SubscriptionsOverviewView: View {
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \Subscription.title) private var subscriptions: [Subscription]

    var body: some View {
		Group {
			if subscriptions.count != 0 {
				Text("subs")
				ForEach(subscriptions) { subscription in
//					TODO: video grid
				}
			} else {
				Text("No subscriptions yet")
			}
		}
    }
}
