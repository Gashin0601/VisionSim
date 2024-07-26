import SwiftUI
import CoreData
import CoreImage.CIFilterBuiltins

struct VisualSimulationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var visualSimulation: VisualSimulation
    @State private var isEditMode = false
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false

    var body: some View {
        VStack {
            if !isEditMode {
                // 表示モード
                VStack(alignment: .center) {
                    Text("☑︎ シミュレーション済みの画像")
                        .font(.headline)
                    VisualSimulationComponent(
                        image: selectedImage ?? UIImage(systemName: "photo")!,
                        blurAmount: CGFloat(visualSimulation.blurriness)
                    )
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                }
                
                VStack(alignment: .center) {
                    Text("☐ 通常の画像")
                        .font(.headline)
                    Image(uiImage: selectedImage ?? UIImage(systemName: "photo")!)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                }
                
                Spacer()
                
                Button("プリセットを編集") {
                    isEditMode = true
                }
                .frame(maxWidth: .infinity)
            } else {
                // 編集モード
                VStack(alignment: .center) {
                    Text("☑︎ シミュレーション済みの画像")
                        .font(.headline)
                    VisualSimulationComponent(
                        image: selectedImage ?? UIImage(systemName: "photo")!,
                        blurAmount: CGFloat(visualSimulation.blurriness)
                    )
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                }
                
                Button("写真を選択") {
                    isImagePickerPresented = true
                }
                .padding()
                .frame(maxWidth: .infinity)
                
                Text("ぼやけ")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Slider(value: Binding(
                    get: { self.visualSimulation.blurriness },
                    set: { newValue in
                        self.visualSimulation.blurriness = newValue
                        self.saveContext()
                    }
                ), in: 0...100, step: 0.5)
                Text("ぼやけの度合い: \(visualSimulation.blurriness, specifier: "%.1f")")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Button("編集を終了") {
                    isEditMode = false
                    saveChanges()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { _ in
            saveChanges()
        }
        .onAppear(perform: loadImage)
        .navigationBarTitle("Visual Simulation", displayMode: .inline)
    }

    private func loadImage() {
        if let imageData = visualSimulation.selectedImage?.imageData,
           let image = UIImage(data: imageData) {
            selectedImage = image
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
            print("Context saved successfully")
        } catch {
            print("Failed to save context: \(error)")
        }
    }

    private func saveChanges() {
        if let imageData = selectedImage?.pngData() {
            if visualSimulation.selectedImage == nil {
                let imageEntity = ImageData(context: viewContext)
                imageEntity.id = UUID()
                visualSimulation.selectedImage = imageEntity
            }
            visualSimulation.selectedImage?.imageData = imageData
        }
        
        saveContext()
    }
}

struct VisualSimulationView_Previews: PreviewProvider {
    static var previews: some View {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let visualSimulation = VisualSimulation(context: context)
        visualSimulation.blurriness = 0.5
        return VisualSimulationView(visualSimulation: visualSimulation)
            .environment(\.managedObjectContext, context)
    }
}
