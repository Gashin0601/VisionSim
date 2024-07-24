import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var userName: String = ""
    @State private var presetName: String = ""
    @State private var textFieldData: String = ""
    @State private var textSize: Double = 14.0
    @State private var textWeight: Double = 1.0
    @State private var blurriness: Double = 0.0
    @State private var effectValues: [EffectValue] = []
    @State private var isSelected: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var userIcon: UIImage? = nil
    @State private var isFromCountryside: Bool = false
    @State private var backgroundColor: ColorEntity?
    @State private var textColor: ColorEntity?
    
    @FetchRequest(
        entity: User.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)]
    ) var users: FetchedResults<User>
    
    @FetchRequest(
        entity: ColorEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ColorEntity.colorCode, ascending: true)]
    ) var colors: FetchedResults<ColorEntity>

    @FetchRequest(
        entity: EffectValue.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \EffectValue.effectName, ascending: true)]
    ) var effects: FetchedResults<EffectValue>

    var body: some View {
        VStack {
            Form {
                Section(header: Text("User Information")) {
                    TextField("User Name", text: $userName)
                    Button(action: selectUserIcon) {
                        Text("Select User Icon")
                    }
                    if let userIcon = userIcon {
                        Image(uiImage: userIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                    }
                    Toggle("From Countryside", isOn: $isFromCountryside)
                }

                Section(header: Text("Preset Information")) {
                    TextField("Preset Name", text: $presetName)
                }

                Section(header: Text("Text Settings")) {
                    TextField("Text Field Data", text: $textFieldData)
                    Slider(value: $textSize, in: 10...30, step: 1) {
                        Text("Text Size")
                    }
                    Text("Text Size: \(textSize, specifier: "%.0f")")
                    Slider(value: $textWeight, in: 0...5, step: 0.1) {
                        Text("Text Weight")
                    }
                    Text("Text Weight: \(textWeight, specifier: "%.1f")")
                    
                    Picker("Background Color", selection: $backgroundColor) {
                        ForEach(colors, id: \.self) { color in
                            Text(color.colorCode ?? "Unknown")
                                .tag(color as ColorEntity?)
                        }
                    }
                    
                    Picker("Text Color", selection: $textColor) {
                        ForEach(colors, id: \.self) { color in
                            Text(color.colorCode ?? "Unknown")
                                .tag(color as ColorEntity?)
                        }
                    }
                }

                Section(header: Text("Visual Simulation")) {
                    Slider(value: $blurriness, in: 0...1, step: 0.1) {
                        Text("Blurriness")
                    }
                    Text("Blurriness: \(blurriness, specifier: "%.1f")")
                }

                Section(header: Text("Effect Values")) {
                    ForEach(effects, id: \.self) { effect in
                        HStack {
                            Text(effect.effectName ?? "Unknown")
                            Slider(value: Binding(
                                get: {
                                    effect.value
                                },
                                set: { newValue in
                                    effect.value = newValue
                                }
                            ), in: 0...1, step: 0.1)
                        }
                    }
                }

                Section(header: Text("Image")) {
                    Button(action: selectImage) {
                        Text("Select Image")
                    }
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                }
            }

            Button("Add Data") {
                addData()
            }
            .padding()

            List {
                ForEach(users) { user in
                    VStack(alignment: .leading) {
                        Text("User: \(user.name ?? "Unknown")")
                        Text("From Countryside: \(user.isFromCountryside ? "Yes" : "No")")
                        if let presets = user.presets as? Set<Preset> {
                            ForEach(Array(presets)) { preset in
                                Text("  Preset: \(preset.name ?? "Unknown")")
                                if let textSetting = preset.textSetting {
                                    Text("    Text Field Data: \(textSetting.textFieldData ?? "Unknown")")
                                    Text("    Background Color: \(textSetting.backgroundColor?.colorCode ?? "Unknown")")
                                    Text("    Text Color: \(textSetting.textColor?.colorCode ?? "Unknown")")
                                }
                                if let visualSimulation = preset.visualSimulation {
                                    Text("    Blurriness: \(visualSimulation.blurriness)")
                                    if let selectedImage = visualSimulation.selectedImage {
                                        Text("    Image: \(selectedImage.imageData?.count ?? 0) bytes")
                                    }
                                }
                                if let effectValues = preset.effectValues as? Set<EffectValue> {
                                    ForEach(Array(effectValues)) { effectValue in
                                        Text("      Effect: \(effectValue.effectName ?? "Unknown") - \(effectValue.value)")
                                    }
                                }
                            }
                        }
                    }
                }
                .onDelete(perform: deleteUsers)
            }

            Button("Fetch Data") {
                fetchData()
            }
            .padding()
        }
    }

    private func selectUserIcon() {
        let picker = UIImagePickerController()
        picker.delegate = ImagePickerDelegate(didFinishPicking: { image in
            self.userIcon = image
        })
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
    }

    private func selectImage() {
        let picker = UIImagePickerController()
        picker.delegate = ImagePickerDelegate(didFinishPicking: { image in
            self.selectedImage = image
        })
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
    }

    private func addData() {
        CoreDataManager.shared.addUser(
            name: userName,
            isFromCountryside: isFromCountryside,
            userIcon: userIcon,
            presetName: presetName,
            textFieldData: textFieldData,
            textSize: textSize,
            textWeight: textWeight,
            backgroundColor: backgroundColor,
            textColor: textColor,
            blurriness: blurriness,
            selectedImage: selectedImage,
            effects: Array(effects),
            context: viewContext
        )
    }

    private func fetchData() {
        let users = CoreDataManager.shared.fetchUsers(context: viewContext)
        for user in users {
            print("User: \(user.name ?? "Unknown")")
            if let userIconData = user.icon?.imageData {
                print("  Icon: \(userIconData.count) bytes")
            }
            print("  From Countryside: \(user.isFromCountryside ? "Yes" : "No")")
            if let presets = user.presets as? Set<Preset> {
                for preset in presets {
                    print("  Preset: \(preset.name ?? "Unknown")")
                    if let textSetting = preset.textSetting {
                        print("    Text Field Data: \(textSetting.textFieldData ?? "Unknown")")
                        print("    Background Color: \(textSetting.backgroundColor?.colorCode ?? "Unknown")")
                        print("    Text Color: \(textSetting.textColor?.colorCode ?? "Unknown")")
                    }
                    if let visualSimulation = preset.visualSimulation {
                        print("    Blurriness: \(visualSimulation.blurriness)")
                        if let selectedImage = visualSimulation.selectedImage {
                            print("    Image: \(selectedImage.imageData?.count ?? 0) bytes")
                        }
                    }
                    if let effectValues = preset.effectValues as? Set<EffectValue> {
                        for effectValue in effectValues {
                            print("      Effect: \(effectValue.effectName ?? "Unknown") - \(effectValue.value)")
                        }
                    }
                }
            }
        }
    }

    private func deleteUsers(offsets: IndexSet) {
        withAnimation {
            offsets.map { users[$0] }.forEach { user in
                CoreDataManager.shared.deleteUser(user, context: viewContext)
            }
        }
    }
}

class ImagePickerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var didFinishPicking: (UIImage) -> Void

    init(didFinishPicking: @escaping (UIImage) -> Void) {
        self.didFinishPicking = didFinishPicking
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            didFinishPicking(editedImage)
        } else if let originalImage = info[.originalImage] as? UIImage {
            didFinishPicking(originalImage)
        }
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension UIColor {
    static func color(data: Data) -> UIColor? {
        return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor
    }

    func encode() -> Data {
        return try! NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }
}

extension UIImage {
    func generateThumbnail(width: CGFloat = 100) -> UIImage? {
        let aspectSize = CGSize(width: width, height: width * size.height / size.width)
        UIGraphicsBeginImageContextWithOptions(aspectSize, false, 0.0)
        draw(in: CGRect(origin: .zero, size: aspectSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return thumbnail
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext

        ContentView()
            .environment(\.managedObjectContext, context)
    }
}

