import SwiftUI
import SwiftData

@main
struct VeilaApp: App {
	var sharedModelContainer: ModelContainer = {
		ContentService.shared.startPythonServer()

        let schema = Schema([
//            Channel.self,
        ])
        
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [config])

            let context = ModelContext(container)
//            let fetch = FetchDescriptor<Channel>()
//            if (try? context.fetch(fetch).isEmpty) ?? true {
//                if let url = URL(string: "https://www.youtube.com/feeds/videos.xml?channel_id=UCPZmuYIinAErjd1LXvzSHoQ") {
//                    let example = Channel(name: "F1nn5ter Daily", link: url)
//                    context.insert(example)
//                    try? context.save()
//                }
//            }

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
