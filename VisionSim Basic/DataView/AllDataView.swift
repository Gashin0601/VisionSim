import SwiftUI
import CoreData

struct AllDataView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: User.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)]
    ) var users: FetchedResults<User>

    @FetchRequest(
        entity: Preset.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Preset.name, ascending: true)]
    ) var presets: FetchedResults<Preset>

    @FetchRequest(
        entity: TextSetting.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TextSetting.textFieldData, ascending: true)]
    ) var textSettings: FetchedResults<TextSetting>

    @FetchRequest(
        entity: VisualSimulation.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \VisualSimulation.blurriness, ascending: true)]
    ) var visualSimulations: FetchedResults<VisualSimulation>

    @FetchRequest(
        entity: ColorEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ColorEntity.colorCode, ascending: true)]
    ) var colorEntities: FetchedResults<ColorEntity>

    @FetchRequest(
        entity: EffectValue.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \EffectValue.effectName, ascending: true)]
    ) var effectValues: FetchedResults<EffectValue>

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Users")) {
                    ForEach(users) { user in
                        NavigationLink(destination: UserDetailView(user: user)) {
                            HStack {
                                Text(user.name ?? "Unnamed User")
                                Spacer()
                                Text(user.isFromCountryside ? "Countryside" : "City")
                            }
                        }
                    }
                }

                Section(header: Text("Presets")) {
                    ForEach(presets) { preset in
                        NavigationLink(destination: PresetDetailView(preset: preset)) {
                            HStack {
                                Text(preset.name ?? "Unnamed Preset")
                                Spacer()
                                Text(preset.user?.name ?? "Unknown User")
                            }
                        }
                    }
                }

                Section(header: Text("Text Settings")) {
                    ForEach(textSettings) { textSetting in
                        NavigationLink(destination: TextSettingDetailView(textSetting: textSetting)) {
                            HStack {
                                Text(textSetting.textFieldData ?? "Unnamed Text Setting")
                                Spacer()
                                Text("Size: \(textSetting.textSize, specifier: "%.0f")")
                                Text("Weight: \(textSetting.textWeight, specifier: "%.1f")")
                                Text("BG Color: \(textSetting.backgroundColor?.colorCode ?? "None")")
                                Text("Text Color: \(textSetting.textColor?.colorCode ?? "None")")
                            }
                        }
                    }
                }

                Section(header: Text("Visual Simulations")) {
                    ForEach(visualSimulations) { visualSimulation in
                        NavigationLink(destination: VisualSimulationDetailView(visualSimulation: visualSimulation)) {
                            HStack {
                                Text("Blurriness: \(visualSimulation.blurriness, specifier: "%.2f")")
                                Spacer()
                                if let imageData = visualSimulation.selectedImage?.imageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                } else {
                                    Text("No image")
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Color Entities")) {
                    ForEach(colorEntities) { colorEntity in
                        HStack {
                            Text(colorEntity.colorCode ?? "Unnamed Color")
                            Spacer()
                        }
                    }
                }

                Section(header: Text("Effect Values")) {
                    ForEach(effectValues) { effectValue in
                        HStack {
                            Text(effectValue.effectName ?? "Unnamed Effect")
                            Spacer()
                            Text("\(effectValue.value, specifier: "%.2f")")
                        }
                    }
                }
            }
            .navigationBarTitle("All Data", displayMode: .inline)
        }
    }
}

struct AllDataView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext

        AllDataView()
            .environment(\.managedObjectContext, context)
    }
}
