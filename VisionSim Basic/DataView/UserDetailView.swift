import SwiftUI
import CoreData

struct UserDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var user: User

    var body: some View {
        Form {
            Section(header: Text("User Details")) {
                TextField("Name", text: Binding(
                    get: { user.name ?? "" },
                    set: { user.name = $0 }
                ))
                Toggle("From Countryside", isOn: $user.isFromCountryside)
            }

            Section(header: Text("Presets")) {
                if let presets = user.presets as? Set<Preset> {
                    ForEach(Array(presets), id: \.self) { preset in
                        Text(preset.name ?? "Unnamed Preset")
                    }
                    .onDelete { indices in
                        deletePresets(at: indices, from: presets)
                    }
                }
            }
        }
        .navigationBarTitle("User Details", displayMode: .inline)
        .onDisappear {
            saveContext()
        }
    }

    private func deletePresets(at offsets: IndexSet, from presets: Set<Preset>) {
        offsets.map { Array(presets)[$0] }.forEach(viewContext.delete)
        saveContext()
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

struct UserDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext

        let user = User(context: context)
        user.name = "Sample User"

        return UserDetailView(user: user)
            .environment(\.managedObjectContext, context)
    }
}
