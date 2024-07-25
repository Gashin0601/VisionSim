import SwiftUI
import CoreImage.CIFilterBuiltins

struct VisualSimulationComponent: View {
    var image: UIImage
    var blurAmount: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: applyBlur(to: image, amount: normalizedBlurAmount(blurAmount)))
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
    }

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
    
    private func normalizedBlurAmount(_ value: CGFloat) -> CGFloat {
        // 0-100のスケールを0-10のスケールに変換
        return value / 10.0
    }
}

// プレビュー用の拡張
struct VisualSimulationComponent_Previews: PreviewProvider {
    static var previews: some View {
        VisualSimulationComponent(image: UIImage(systemName: "photo")!, blurAmount: 50)
            .previewLayout(.fixed(width: 300, height: 300))
    }
}
