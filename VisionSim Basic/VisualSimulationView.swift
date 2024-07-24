import SwiftUI
import CoreData
import CoreImage.CIFilterBuiltins

struct VisualSimulationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var visualSimulation: VisualSimulation
    @State private var isEditMode = false
    @State private var selectedImage: UIImage?
    @State private var blurredImage: UIImage?
    @State private var isImagePickerPresented = false

    var body: some View {
        VStack {
            if !isEditMode {
                // 表示モード
                VStack(alignment: .leading) {
                    Text("☑︎ シミュレーション済みの画像")
                        .font(.headline)
                    Image(uiImage: blurredImage ?? selectedImage ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
                
                VStack(alignment: .leading) {
                    Text("☐ 通常の画像")
                        .font(.headline)
                    Image(uiImage: selectedImage ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
                
                Spacer()
                
                Button("プリセットを編集") {
                    isEditMode = true
                }
            } else {
                // 編集モード
                VStack(alignment: .leading) {
                    Text("☑︎ シミュレーション済みの画像")
                        .font(.headline)
                    Image(uiImage: blurredImage ?? selectedImage ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
                
                Button("写真を選択") {
                    isImagePickerPresented = true
                }
                .padding()
                
                Text("ぼやけ")
                Slider(value: Binding(
                    get: { self.visualSimulation.blurriness },
                    set: { newValue in
                        self.visualSimulation.blurriness = newValue
                        self.applyBlurEffect()
                        self.saveContext()
                    }
                ), in: 0...100, step: 0.5)
                Text("ぼやけの度合い: \(visualSimulation.blurriness, specifier: "%.1f")")
                
                Spacer()
                
                Button("編集を終了") {
                    isEditMode = false
                    saveChanges()
                }
            }
        }
        .padding()
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { _ in
            applyBlurEffect()
        }
        .onAppear(perform: loadImage)
        .navigationBarTitle("Visual Simulation", displayMode: .inline)
    }

    private func loadImage() {
        if let imageData = visualSimulation.selectedImage?.imageData,
           let image = UIImage(data: imageData) {
            selectedImage = image
            applyBlurEffect()
        }
    }

    private func applyBlurEffect() {
        guard let inputImage = selectedImage else { return }
        guard let ciImage = CIImage(image: inputImage) else { return }
        
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = ciImage
        filter.radius = Float(visualSimulation.blurriness / 10)
        
        guard let outputImage = filter.outputImage else { return }
        
        let context = CIContext()
        if let cgImage = context.createCGImage(outputImage, from: ciImage.extent) {
            blurredImage = UIImage(cgImage: cgImage, scale: inputImage.scale, orientation: inputImage.imageOrientation)
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
