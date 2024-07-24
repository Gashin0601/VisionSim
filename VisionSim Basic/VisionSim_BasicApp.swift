import SwiftUI
import CoreData

@main
struct VisionSimBasicApp: App {
    let persistenceController = PersistenceController.shared
    @State private var showTutorial = !UserDefaults.standard.bool(forKey: "isFirstLaunch")

    var body: some Scene {
        WindowGroup {
            if showTutorial {
                TutorialView(showTutorial: $showTutorial)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .onDisappear {
                        UserDefaults.standard.set(true, forKey: "isFirstLaunch")
                    }
            } else {
                HomeView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
