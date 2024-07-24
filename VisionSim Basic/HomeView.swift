import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: User.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)]
    ) var users: FetchedResults<User>

    @State private var isLoadingFile = false
    @State private var isExportingPreset = false
    @State private var presetToExport: Preset?
    @State private var showingDebugAlert = false
    @State private var debugMessage = ""
    @State private var newPreset: Preset?
    @State private var isShowingNewPreset = false
    @State private var otherPresets: [Preset] = []
    @State private var selectedPreset: Preset?
    @State private var selectedTab: Int = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                
                if let currentUser = users.first(where: { $0.isFromCountryside }) {
                    userContentView(for: currentUser)
                } else {
                    noUserView
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showingDebugAlert) {
                Alert(title: Text("Debug Info"), message: Text(debugMessage), dismissButton: .default(Text("OK")))
            }
            .background(
                Group {
                    if let newPreset = newPreset {
                        NavigationLink(destination: PresetDetailView(preset: newPreset, selectedTab: 0), isActive: $isShowingNewPreset) {
                            EmptyView()
                        }
                    }
                    NavigationLink(
                        destination: selectedPreset.map { PresetDetailView(preset: $0, selectedTab: selectedTab) },
                        isActive: Binding(
                            get: { selectedPreset != nil },
                            set: { if !$0 { selectedPreset = nil } }
                        )
                    ) {
                        EmptyView()
                    }
                }
            )
            .onAppear {
                loadOtherPresets()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Spacer()
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape.fill")
                    .imageScale(.large)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            .padding()
        }
    }
    
    private func userContentView(for user: User) -> some View {
        VStack {
            Text("こんにちは、\(user.name ?? "ユーザー")さん")
                .font(.largeTitle)
                .padding()

            List {
                userPresetsSection(for: user)
                otherPresetsSection
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
    
    private func userPresetsSection(for user: User) -> some View {
        Section(header: userPresetsSectionHeader) {
            if let presets = user.presets as? Set<Preset>, !presets.isEmpty {
                ForEach(Array(presets).sorted(by: { $0.name ?? "" < $1.name ?? "" }), id: \.self) { preset in
                    presetRow(for: preset)
                }
            } else {
                Text("プリセットがありません")
            }
        }
    }
    
    private var userPresetsSectionHeader: some View {
        HStack {
            Text("あなたのプリセット")
                .font(.title2)
            Spacer()
            Button(action: createAndNavigateToNewPreset) {
                Image(systemName: "plus.circle.fill")
                    .imageScale(.large)
            }
        }
    }
    
    private func presetRow(for preset: Preset) -> some View {
        NewCompornent(preset: preset,
                      onTextSettingsTap: {
                          self.selectedPreset = preset
                          self.selectedTab = 0
                      },
                      onVisualSimulationTap: {
                          self.selectedPreset = preset
                          self.selectedTab = 1
                      })
    }
        
    private var otherPresetsSection: some View {
        Section(header: otherPresetsSectionHeader) {
            if otherPresets.isEmpty {
                Text("その他のプリセットはありません")
            } else {
                ForEach(otherPresets, id: \.self) { preset in
                    presetRow(for: preset)
                }
                .onDelete(perform: deleteOtherPresets)
            }
        }
    }

    private var otherPresetsSectionHeader: some View {
        HStack {
            Text("その他")
                .font(.title2)
            Spacer()
            Button(action: {
                isLoadingFile.toggle()
            }) {
                Image(systemName: "arrow.down.circle.fill")
                    .imageScale(.large)
            }
            .fileImporter(
                isPresented: $isLoadingFile,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let files):
                    guard let file = files.first else {
                        debugMessage = "ファイルが選択されていません"
                        showingDebugAlert = true
                        return
                    }
                    
                    let gotAccess = file.startAccessingSecurityScopedResource()
                    defer {
                        if gotAccess {
                            file.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    if !gotAccess {
                        debugMessage = "ファイルへのアクセス権限を取得できませんでした"
                        showingDebugAlert = true
                        return
                    }
                    
                    do {
                        let data = try Data(contentsOf: file)
                        let decoder = JSONDecoder()
                        let presetData = try decoder.decode(PresetData.self, from: data)
                        
                        createPresetFromData(presetData)
                        try viewContext.save()
                        debugMessage = "プリセットを正常に読み込みました"
                        showingDebugAlert = true
                        loadOtherPresets()
                    } catch {
                        debugMessage = "ファイルの読み込みに失敗しました: \(error.localizedDescription)"
                        showingDebugAlert = true
                    }
                case .failure(let error):
                    debugMessage = "ファイルの選択に失敗しました: \(error.localizedDescription)"
                    showingDebugAlert = true
                }
            }
        }
    }
    
    private var noUserView: some View {
        VStack {
            Text("ユーザーが設定されていません")
                .font(.title2)
                .padding()
            
            NavigationLink(destination: TutorialView(showTutorial: .constant(true))) {
                Text("チュートリアルを開始")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }

    private func createAndNavigateToNewPreset() {
        guard let currentUser = users.first(where: { $0.isFromCountryside }) else {
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
            isShowingNewPreset = true
        } catch {
            debugMessage = "新規プリセットの保存に失敗しました: \(error.localizedDescription)"
            showingDebugAlert = true
        }
    }

    private func generateNewPresetName() -> String {
        let existingPresets = users.first(where: { $0.isFromCountryside })?.presets?.allObjects as? [Preset] ?? []
        let existingNames = Set(existingPresets.compactMap { $0.name })
        
        var index = 0
        var newName: String
        
        repeat {
            if index == 0 {
                newName = "新規プリセット"
            } else {
                newName = "新規プリセット \(index)"
            }
            index += 1
        } while existingNames.contains(newName)
        
        return newName
    }

    private func createPresetFromData(_ presetData: PresetData) {
        let preset = Preset(context: viewContext)
        preset.id = UUID()
        preset.name = presetData.name
        
        let textSetting = TextSetting(context: viewContext)
        textSetting.id = UUID()
        textSetting.textFieldData = presetData.textSetting.textFieldData
        textSetting.textSize = presetData.textSetting.textSize
        textSetting.textWeight = presetData.textSetting.textWeight
        
        if let colorCode = presetData.textSetting.colorCode {
            let fetchRequest: NSFetchRequest<ColorEntity> = ColorEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "colorCode == %@", colorCode)
            
            do {
                let results = try viewContext.fetch(fetchRequest)
                if let existingColor = results.first {
                    textSetting.backgroundColor = existingColor
                    textSetting.textColor = existingColor
                } else {
                    let newColor = ColorEntity(context: viewContext)
                    newColor.id = UUID()
                    newColor.colorCode = colorCode
                    newColor.backgroundColorCode = presetData.textSetting.backgroundColorCode ?? "#FFFFFF"
                    newColor.textColorCode = presetData.textSetting.textColorCode ?? "#000000"
                    textSetting.backgroundColor = newColor
                    textSetting.textColor = newColor
                }
            } catch {
                print("Failed to fetch or create ColorEntity: \(error)")
            }
        }
        
        preset.textSetting = textSetting

        let visualSimulation = VisualSimulation(context: viewContext)
        visualSimulation.id = UUID()
        visualSimulation.blurriness = presetData.visualSimulation.blurriness

        if let imageData = presetData.visualSimulation.imageData {
            let image = ImageData(context: viewContext)
            image.id = UUID()
            image.imageData = imageData
            visualSimulation.selectedImage = image
        }

        preset.visualSimulation = visualSimulation

        let user = fetchOrCreateUser(with: presetData.user)
        user.addToPresets(preset)
    }

    private func fetchOrCreateUser(with userData: UserData) -> User {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", userData.name)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let existingUser = results.first {
                return existingUser
            } else {
                let newUser = User(context: viewContext)
                newUser.id = UUID()
                newUser.name = userData.name
                newUser.isFromCountryside = userData.isFromCountryside
                return newUser
            }
        } catch {
            debugMessage = "ユーザーの取得または作成に失敗しました: \(error.localizedDescription)"
            showingDebugAlert = true
            return User(context: viewContext)
        }
    }

    private func loadOtherPresets() {
        otherPresets = users.filter { !$0.isFromCountryside }
            .flatMap { $0.presets?.allObjects as? [Preset] ?? [] }
            .sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    private func deleteOtherPresets(at offsets: IndexSet) {
        for index in offsets {
            let preset = otherPresets[index]
            viewContext.delete(preset)
        }
        otherPresets.remove(atOffsets: offsets)
        saveContext()
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            debugMessage = "Failed to save context: \(error.localizedDescription)"
            showingDebugAlert = true
        }
    }
}

struct PresetData: Codable {
    let name: String
    let textSetting: TextSettingData
    let visualSimulation: VisualSimulationData
    let user: UserData
}

struct TextSettingData: Codable {
    let textFieldData: String
    let textSize: Double
    let textWeight: Double
    let colorCode: String?
    let backgroundColorCode: String?
    let textColorCode: String?
}

struct VisualSimulationData: Codable {
    let blurriness: Double
    let imageData: Data?
}

struct UserData: Codable {
    let name: String
    let isFromCountryside: Bool
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let persistenceController = PersistenceController.shared
        let context = persistenceController.container.viewContext

        HomeView()
            .environment(\.managedObjectContext, context)
    }
}
