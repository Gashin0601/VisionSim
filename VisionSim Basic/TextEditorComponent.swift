import SwiftUI

struct TextEditorComponent: UIViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat
    var fontWeightValue: Double
    var textColor: UIColor
    var backgroundColor: UIColor
    var isEditable: Bool
    var padding: UIEdgeInsets = .init(top: 15, left: 15, bottom: 15, right: 15) // デフォルトの余白
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.backgroundColor = backgroundColor
        textView.textColor = textColor
        textView.font = UIFont.systemFont(ofSize: fontSize, weight: getFontWeight(from: fontWeightValue))
        textView.text = text
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.delegate = context.coordinator
        textView.textContainerInset = padding // ここで余白を設定
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        uiView.textColor = textColor
        uiView.backgroundColor = backgroundColor
        uiView.isEditable = isEditable
        uiView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        uiView.textContainer.lineFragmentPadding = 0
        uiView.textContainerInset = padding // ここでも余白を設定
        
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: UIFont.systemFont(ofSize: fontSize, weight: getFontWeight(from: fontWeightValue))
        ]
        uiView.attributedText = NSAttributedString(string: text, attributes: attributes)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextEditorComponent

        init(_ parent: TextEditorComponent) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
    
    private func getFontWeight(from value: Double) -> UIFont.Weight {
        let clampedValue = min(max(value, 0.0), 1.0) // 0.0 から 1.0 の範囲に制限
        switch clampedValue {
            case 0.0..<0.2: return .ultraLight
            case 0.2..<0.4: return .light
            case 0.4..<0.6: return .regular
            case 0.6..<0.8: return .semibold
            case 0.8...1.0: return .bold
            default: return .regular
        }
    }
}

struct CustomTextEditor_Previews: PreviewProvider {
    static var previews: some View {
        TextEditorComponent(
            text: .constant("サンプルテキスト"),
            fontSize: 18,
            fontWeightValue: 0.2,
            textColor: .white,
            backgroundColor: .black,
            isEditable: true
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
