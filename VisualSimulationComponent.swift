import SwiftUI
import CoreImage.CIFilterBuiltins

/// ビジュアルシミュレーションを表示するコンポーネント
struct VisualSimulationComponent: View {
    var image: UIImage
    var blurAmount: CGFloat
    
    @State private var processedImage: UIImage?
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let processedImage = processedImage {
                    Image(uiImage: processedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    ProgressView()
                }
            }
        }
        .onAppear {
            processImage()
        }
        .onChange(of: blurAmount) { _ in
            processImage()
        }
    }
    
    /// 画像にぼかし効果を適用する
    private func processImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let processed = applyBlur(to: image, amount: normalizedBlurAmount(blurAmount))
            DispatchQueue.main.async {
                self.processedImage = processed
            }
        }
    }

    /// 画像にガウスぼかしを適用する
    private func applyBlur(to image: UIImage, amount: CGFloat) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = ciImage
        filter.radius = Float(amount)

        guard let outputImage = filter.outputImage,
              let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    /// ぼかし量を正規化する
    private func normalizedBlurAmount(_ value: CGFloat) -> CGFloat {
        // 0-100のスケールを0-50のスケールに変換
        return value / 2
    }
}
