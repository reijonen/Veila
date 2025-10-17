import SwiftUI
import SwiftData

extension Settings {
	static func shared(context: ModelContext) throws -> Settings {
		// Fetch the first Settings object
		let settings = try context.fetch(FetchDescriptor<Settings>()).first

		if let existing = settings {
			return existing
		}

		let newSettings = Settings()
		context.insert(newSettings)
		try context.save()
		return newSettings
	}
}
@main
struct VeilaApp: App {
	var sharedModelContainer: ModelContainer = {
		ContentService.shared.startPythonServer()

        let schema = Schema([
			Settings.self,
			Subscription.self,
			Playlist.self
        ])
        
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [config])

            return container
        } catch {
            fatalError("Could not create ModelContainer: ${error}")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .modelContainer(sharedModelContainer)
    }
}
