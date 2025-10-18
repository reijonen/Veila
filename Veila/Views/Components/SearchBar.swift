import SwiftUI

struct SearchBarView: View {
	@State private var searchText: String = ""

	@Binding var selection: SidebarSelection
	@Binding var isSearching: Bool
	@Binding var searchResults: Array<VideoDTO>

	var body: some View {
		TextField("Search", text: $searchText)
			.textFieldStyle(.roundedBorder)
			.padding(.leading, 6)
			.frame(width: 300)
			.disabled(isSearching)
			.opacity(isSearching ? 0.6 : 1.0)
			.onSubmit {
				if !isSearching {
					Task {
						await doSearch()
					}
				}
			}

		Button {
			if !isSearching {
				Task {
					await doSearch()
				}
			}
		} label: {
			Image(systemName: "magnifyingglass")
		}
		.disabled(isSearching)
		.opacity(isSearching ? 0.6 : 1.0)
	}

	private func doSearch() async {
		await MainActor.run {
			self.selection = .search
			self.isSearching = true
		}

		do {
			let results = try await ContentService.shared.search(query: self.searchText)

//			print("Search results:", results)

			await MainActor.run {
				self.searchResults = results
				self.isSearching = false
			}
		} catch {
			print("Failed to search: \(error)")
		}
	}
}
