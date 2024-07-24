import SwiftUI
import CoreData

struct TextSettingDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var textSetting: TextSetting

    @FetchRequest(
        entity: ColorEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ColorEntity.colorCode, ascending: true)]
    ) var colors: FetchedResults<ColorEntity>

    var body: some View {
        Form {
            Section(header: Text("Text Settings")) {
                TextField("Text Field Data", text: Binding(
                    get: { textSetting.textFieldData ?? "" },
                    set: { textSetting.textFieldData = $0 }
                ))
                Slider(value: $textSetting.textSize, in: 10...30, step: 1) {
                    Text("Text Size")
                }
                Text("Text Size: \(textSetting.textSize, specifier: "%.0f")")
                Slider(value: $textSetting.textWeight, in: 0...5, step: 0.1) {
                    Text("Text Weight")
                }
                Text("Text Weight: \(textSetting.textWeight, specifier: "%.1f")")
                
                Picker("Background Color", selection: $textSetting.backgroundColor) {
                    ForEach(colors, id: \.self) { color in
                        Text(color.colorCode ?? "Unknown")
                            .tag(color as ColorEntity?)
                    }
                }
                
                Picker("Text Color", selection: $textSetting.textColor) {
                    ForEach(colors, id: \.self) { color in
                        Text(color.colorCode ?? "Unknown")
                            .tag(color as ColorEntity?)
                    }
                }
            }
        }
        .navigationBarTitle("Text Settings", displayMode: .inline)
        .onDisappear {
            saveContext()
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

struct TextSettingDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext

        let textSetting = TextSetting(context: context)
        textSetting.textFieldData = "Sample Text"
        textSetting.textSize = 14.0
        textSetting.textWeight = 1.0

        return TextSettingDetailView(textSetting: textSetting)
            .environment(\.managedObjectContext, context)
    }
}
