import SwiftUI
import SwiftData

@main
struct VeilaApp: App {
	var sharedModelContainer: ModelContainer = {
		ContentService.shared.startPythonServer()

        let schema = Schema([
			Subscription.self
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
