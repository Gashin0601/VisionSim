import SwiftUI
import CoreImage.CIFilterBuiltins

struct VisualSimulationComponent: View {
    var image: UIImage
    var blurAmount: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: applyBlur(to: image, amount: blurAmount))
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
}
