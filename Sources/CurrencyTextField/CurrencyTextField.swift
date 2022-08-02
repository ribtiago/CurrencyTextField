import SwiftUI
import Combine


public struct CurrencyTextField: UIViewRepresentable {
    
    
    @Environment(\.locale) var locale
    @Binding private var value: Decimal
    private let currencyCode: String?
    
    private var style: UITextField.BorderStyle = .none
    private var font: UIFont?
    private var keyboardType: UIKeyboardType = .decimalPad
    private var foregroundColor: Color = .primary
    
    public init(value: Binding<Decimal>, currencyCode: String? = nil) {
        self._value = value
        self.currencyCode = currencyCode
    }
    
    public func makeUIView(context: Context) -> AmountTextField {
        let textField = AmountTextField(locale: self.locale, currencyCode: self.currencyCode)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.required, for: .vertical)
        textField.borderStyle = self.style
        textField.font = self.font
        textField.keyboardType = self.keyboardType
        textField.textColor = UIColor(self.foregroundColor)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        return textField
    }
    
    public func updateUIView(_ uiView: AmountTextField, context: Context) {
        if self.value != uiView.amount {
            uiView.amount = self.value
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    public class Coordinator: NSObject, UITextFieldDelegate {
        private let parent: CurrencyTextField
        
        init(_ parent: CurrencyTextField) {
            self.parent = parent
        }
        
        @objc func textFieldDidChange(_ textField: AmountTextField) {
            self.parent.value = textField.amount
        }
    }
}

public extension CurrencyTextField {
    
    func textFieldStyle<Style>(_ style: Style) -> CurrencyTextField where Style: TextFieldStyle {
        var textField = self
        if style is RoundedBorderTextFieldStyle {
            textField.style = .roundedRect
        }
        else {
            textField.style = .none
        }
        return textField
    }
    
    func font(_ font: UIFont?) -> CurrencyTextField {
        var textField = self
        textField.font = font
        return textField
    }
    
    func foregroundColor(_ color: Color) -> CurrencyTextField {
        var textField = self
        textField.foregroundColor = color
        return textField
    }
    
    func keyboardType(_ type: UIKeyboardType) -> CurrencyTextField {
        var textField = self
        textField.keyboardType = type
        return textField
    }
}

#if DEBUG
struct CurrencyTextField_Previews: PreviewProvider {
    static var previews: some View {
        CurrencyTextField(value: .constant(0), currencyCode: "EUR")
            .font(UIFont.systemFont(ofSize: 36))
            .textFieldStyle(.roundedBorder)
            .foregroundColor(.gray)
            .keyboardType(.decimalPad)
            .environment(\.locale, Locale(identifier: "pt_PT"))
//            .preferredColorScheme(.dark)
    }
}
#endif
