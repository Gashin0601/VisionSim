import SwiftUI
import CoreData

struct AddPresetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @State private var navigateToPresetDetail = false
    @State private var newPreset: Preset?

    @FetchRequest(
        entity: User.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)],
        predicate: NSPredicate(format: "isFromCountryside == %@", NSNumber(value: true))
    ) var users: FetchedResults<User>

    var body: some View {
        VStack {
            if let preset = newPreset {
                NavigationLink(
                    destination: PresetDetailView(preset: preset, selectedTab: 0),
                    isActive: $navigateToPresetDetail
                ) {
                    EmptyView()
                }
            }
        }
        .onAppear(perform: createAndSaveNewPreset)
    }

    private func createAndSaveNewPreset() {
        guard let currentUser = users.first else {
            print("ユーザーが見つかりません")
            return
        }

        let preset = Preset(context: viewContext)
        preset.id = UUID()
        preset.name = generateNewPresetName()
        preset.user = currentUser

        let textSetting = TextSetting(context: viewContext)
        textSetting.id = UUID()
        textSetting.textFieldData = "新しいプリセットのテキスト"
        textSetting.textSize = 18.0
        textSetting.textWeight = 0.5
        preset.textSetting = textSetting

        let visualSimulation = VisualSimulation(context: viewContext)
        visualSimulation.id = UUID()
        visualSimulation.blurriness = 0.0
        preset.visualSimulation = visualSimulation

        do {
            try viewContext.save()
            newPreset = preset
            navigateToPresetDetail = true
        } catch {
            print("新規プリセットの保存に失敗しました: \(error)")
        }
    }

    private func generateNewPresetName() -> String {
        let existingPresets = users.first?.presets?.allObjects as? [Preset] ?? []
        let existingNames = Set(existingPresets.compactMap { $0.name })
        var index = 1
        var newName = "新規プリセット"
        while existingNames.contains(newName) {
            newName = "新規プリセット(\(index))"
            index += 1
        }
        return newName
    }
}

struct AddPresetView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext

        NavigationView {
            AddPresetView()
                .environment(\.managedObjectContext, context)
        }
    }
}
