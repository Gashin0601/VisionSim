import SwiftUI
import CoreData
import CoreImage.CIFilterBuiltins

/// 視覚シミュレーション画面を表すView
struct VisualSimulationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var visualSimulation: VisualSimulation
    @State private var isEditMode = false
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?
    
    // キャッシュ機能：シミュレーション済みの画像をキャッシュする
    @State private var cachedImage: UIImage?

    var body: some View {
        VStack {
            if !isEditMode {
                // 表示モード
                VStack(alignment: .center) {
                    Text("☑︎ シミュレーション済みの画像")
                        .font(.headline)
                    if let cachedImage = cachedImage {
                        // キャッシュされた画像があればそれを表示
                        Image(uiImage: cachedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    } else {
                        // キャッシュがない場合はコンポーネントを利用
                        VisualSimulationComponent(
                            image: selectedImage ?? UIImage(systemName: "photo")!,
                            blurAmount: CGFloat(visualSimulation.blurriness)
                        )
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                    }
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
                        self.updateCachedImage()  // ぼやけ度合いを変更したらキャッシュを更新
                    }
                ), in: 0...100, step: 0.5)
                Text("ぼやけの度合い: \(visualSimulation.blurriness, specifier: "%.1f")")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Button("編集を終了") {
                    isEditMode = false
                    saveContext()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .onChange(of: selectedImage) { newImage in
            if let newImage = newImage {
                print("New image selected: \(newImage)")  // デバッグログ
                // 即座にUIに反映
                cachedImage = newImage
                updateCachedImage() // キャッシュの更新
                saveImage(newImage) // CoreDataに保存
            } else {
                print("Image selection failed")  // デバッグログ
            }
        }
        .onAppear {
            loadImage()
            updateCachedImage()  // 初回表示時にキャッシュを更新
        }
        .navigationBarTitle("Visual Simulation", displayMode: .inline)
    }

    /// 画像をロードする
    private func loadImage() {
        if let imageData = visualSimulation.selectedImage?.imageData,
           let image = UIImage(data: imageData) {
            selectedImage = image
        }
    }

    /// 画像を保存する
    private func saveImage(_ image: UIImage) {
        if let imageData = image.pngData() {
            if visualSimulation.selectedImage == nil {
                let imageEntity = ImageData(context: viewContext)
                imageEntity.id = UUID()
                visualSimulation.selectedImage = imageEntity
            }
            visualSimulation.selectedImage?.imageData = imageData
            saveContext()
        }
    }

    /// コンテキストを保存する
    private func saveContext() {
        do {
            try viewContext.save()
            print("Context saved successfully")
        } catch {
            print("Failed to save context: \(error)")
        }
    }

    /// キャッシュされた画像を更新する
    private func updateCachedImage() {
        if let selectedImage = selectedImage {
            // 非同期でシミュレーションを実行し、結果をキャッシュに保存
            DispatchQueue.global(qos: .userInitiated).async {
                let blurredImage = applyBlur(to: selectedImage, amount: CGFloat(visualSimulation.blurriness))
                DispatchQueue.main.async {
                    print("Cached image updated")  // デバッグログ
                    cachedImage = blurredImage
                }
            }
        } else {
            print("No image selected for caching")  // デバッグログ
        }
    }

    /// 画像にぼかしを適用する
    private func applyBlur(to image: UIImage, amount: CGFloat) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = ciImage
        filter.radius = Float(amount / 2)  // 0-100のスケールを0-50に変換

        guard let outputImage = filter.outputImage,
              let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
