import SwiftUI
import SwiftData

struct HistoryView: View {
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \HistoryItem.date) private var history: [HistoryItem]

    var body: some View {
		VStack {
			Text("History")

			List {
				ForEach(history) { historyItem in
					HStack {
						VStack {
							Text(historyItem.date.description)
							Text(historyItem.video.title)
						}
						Spacer()
						Button(action: { delete(historyItem) }) {
							Image(systemName: "trash")
						}
						.buttonStyle(BorderlessButtonStyle())
					}
				}
			}
		}
	}

	private func delete(_ item: HistoryItem) {
		modelContext.delete(item)
		do {
			try modelContext.save()
		} catch {
			print("Failed to delete item: \(error)")
		}
	}
}
