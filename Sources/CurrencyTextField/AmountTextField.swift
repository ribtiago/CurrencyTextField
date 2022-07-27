//
//  AmountTextField.swift
//  
//
//  Created by Tiago Ribeiro on 23/06/2022.
//

import UIKit

/**
 A UITextField with specific support for currency amount. It adapts itself to the current Locale or to a Locale provided by
 the developer.
 Is subclassed from UnderlinedTextField.
*/

open class AmountTextField: UITextField {
    
    public typealias CurrencyCode = String
    
    public var locale: Locale = Locale.current
    
    public var currencyCode: CurrencyCode? {
        didSet { self.formatValueToCurrencyText() }
    }
    
    public var amount: Decimal {
        get { return self._amount }
        set {
            self._amount = newValue
            self.formatValueToCurrencyText()
        }
    }
    
    private var _amount: Decimal = 0
    
    private weak var forwardDelegate: UITextFieldDelegate?
    
    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 0
        formatter.locale = self.locale

        if let currencyCode = self.currencyCode {
            formatter.currencyCode = currencyCode
        }
        
        guard
            var result = formatter.string(from: 0),
            let range = result.range(of: "0")
        else { return "" }
        
        result.removeSubrange(range)
        return result
    }
    
    private var thousandsSeparator: String {
        let formatter = NumberFormatter()
        formatter.locale = self.locale
        
        if let currencyCode = self.currencyCode {
            formatter.currencyCode = currencyCode
        }
        
        return formatter.groupingSeparator
    }
    
    private var decimalSeparator: String {
        let formatter = NumberFormatter()
        formatter.locale = self.locale
        
        if let currencyCode = self.currencyCode {
            formatter.currencyCode = currencyCode
        }
        
        return formatter.decimalSeparator
    }
    
    private var maximumFractionalDigits: Int {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.locale
        
        if let currencyCode = self.currencyCode {
            formatter.currencyCode = currencyCode
        }
        
        return formatter.maximumFractionDigits
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 0
        formatter.locale = self.locale
        
        if let currencyCode = self.currencyCode {
            formatter.currencyCode = currencyCode
        }
        
        return formatter
    }
    
    open override var delegate: UITextFieldDelegate? {
        get { return self.forwardDelegate }
        set { self.forwardDelegate = newValue }
    }
    
    open override var text: String? {
        get { return super.text }
        set { } // text not accessible
    }
    
    open override var keyboardType: UIKeyboardType {
        get { return super.keyboardType }
        set {
            if [UIKeyboardType.decimalPad, UIKeyboardType.numberPad].contains(newValue) {
                super.keyboardType = newValue
            }
        }
    }
    
    open override func caretRect(for position: UITextPosition) -> CGRect {
        if position == self.endOfDocument {
            return super.caretRect(for: position)
        }
        else {
            return .null
        }
    }
    
    open override var endOfDocument: UITextPosition {
        guard
            let currencySymbolRange = self.text!.range(of: self.currencySymbol),
            currencySymbolRange.lowerBound != self.text!.startIndex
            else { return super.endOfDocument }

        let searchPosition = self.text!.distance(from: self.text!.startIndex, to: currencySymbolRange.lowerBound)
        guard let position = self.position(from: super.beginningOfDocument, offset: searchPosition) else { return super.endOfDocument }

        return position
    }

    open override var selectedTextRange: UITextRange? {
        get { return super.selectedTextRange }
        set { super.selectedTextRange = self.textRange(from: self.endOfDocument, to: self.endOfDocument) }
    }
    
    // MARK: - Initialisation
    public init(locale: Locale = .current, currencyCode: CurrencyCode? = nil) {
        super.init(frame: .zero)
        self.locale = locale
        self.currencyCode = currencyCode
        self.configure()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }

    private func configure() {
        super.delegate = self
        super.keyboardType = .decimalPad
        self.autocorrectionType = .no
        self.formatValueToCurrencyText()
        
        self.addTarget(self, action: #selector(self.amountTextFieldDidChange(_:)), for: .editingChanged)
    }
    
    // MARK: - Delegate forwarding
    
    open override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) {
            return true
        }
        else if let forwardDelegate = self.forwardDelegate {
            return forwardDelegate.responds(to: aSelector)
        }
        else {
            return false
        }
    }

    open override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if super.responds(to: aSelector) {
            return super.forwardingTarget(for: aSelector)
        }
        else if let forwardDelegate = self.forwardDelegate, forwardDelegate.responds(to: aSelector) {
            return forwardDelegate
        }
        else {
            self.doesNotRecognizeSelector(aSelector)
            return nil
        }
    }

    open override func method(for aSelector: Selector!) -> IMP! {
        if let signature = super.method(for: aSelector) {
            return signature
        }
        else {
            return (self.forwardDelegate as? NSObject)?.method(for: aSelector)
        }
    }
    
    // MARK: - Helpers
    
    /*
     The next two implementations of `finishesWithZeroDecimals`
     Check if the current textField text terminates with dot or decimals only composed of zeros
     Examples:
     - 123.
     - 3.0
     - 54.0000000
     - 0.0
    */
    private func finishesWithZeroDecimals() -> Bool {
        var range: NSRange!
        return self.finishesWithZeroDecimals(matchRange: &range)
    }
    
    private func finishesWithZeroDecimals(matchRange: inout NSRange?) -> Bool {
        if let text = self.text?.replacingOccurrences(of: self.currencySymbol, with: ""),
            let regex = try? NSRegularExpression(pattern: "\\\(self.decimalSeparator)$|\\\(self.decimalSeparator)[0-9]*0+$", options: .caseInsensitive),
            let range = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)).first?.range {
            
            matchRange = range
            return true
        }
        return false
    }
    
    private func formatValueToCurrencyText() {
        let previousTextLength: Int = {
            var range: NSRange!
            if self.finishesWithZeroDecimals(matchRange: &range) {
                return self.text!.count - range.length
            }
            return self.text!.count
        }()
        let previousCursorPosition = self.selectedTextRange!.start
        super.text = self.currencyFormatter.string(from: NSDecimalNumber(decimal: self._amount))
        
        if self.selectedTextRange!.start == super.endOfDocument {
            let offset = self.text!.count - previousTextLength
            guard let newCursorPosition = self.position(from: previousCursorPosition, offset: offset) else { return }
            self.repositionCursor(at: newCursorPosition)
        }
    }
    
    private func repositionCursor(at position: UITextPosition) {
        self.selectedTextRange = self.textRange(from: position, to: position)
    }
    
    // MARK: - Format text changed action
    
    @objc private func amountTextFieldDidChange(_ sender: Any) {

        guard
            let text = self.text?
                .replacingOccurrences(of: self.currencySymbol, with: "")
                .components(separatedBy: CharacterSet(charactersIn: self.thousandsSeparator))
                .joined(),
            text != ""
        else {
            self._amount = 0
            self.formatValueToCurrencyText()
            return
        }

        self._amount = NSDecimalNumber(string: text, locale: self.locale).decimalValue
        if self._amount.isNaN {
            self._amount = 0
        }

        if !self.finishesWithZeroDecimals() || self.selectedTextRange!.start != self.endOfDocument {
            self.formatValueToCurrencyText()
        }
    }
}

extension AmountTextField: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.selectedTextRange = self.textRange(from: self.endOfDocument, to: self.endOfDocument)
        self.forwardDelegate?.textFieldDidBeginEditing?(textField)
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let decimalSeparator = self.decimalSeparator
        let puntuationSet = CharacterSet(charactersIn: decimalSeparator)
        let decimalSet = CharacterSet.decimalDigits
        let allowedCharactersSet = decimalSet.union(puntuationSet)

        if string.trimmingCharacters(in: allowedCharactersSet).count > 0 && string != "" {
            return false
        }

        let text: String = textField.text!
        if textField.text!.rangeOfCharacter(from: puntuationSet) != nil && string.rangeOfCharacter(from: puntuationSet) != nil {
            return false
        }

        // Check if we have a decimal separator
        let textRange = Range(range, in: text)!
        let finalString = text.replacingCharacters(in: textRange, with: string)
        if let indexOfDecimalSeparator = finalString.range(of: decimalSeparator) {
            let endOfString = finalString[indexOfDecimalSeparator.upperBound...]
            let fractionalDigits = self.countDecimalsIn(string: endOfString)
            let maximumFractionalDigits = self.maximumFractionalDigits

            // Prevent the users from using the decimal separator if there is a 0 maxFractionalDigit for the given configuration
            if maximumFractionalDigits == 0 {
                return false
            }
            // Check if we have any fractional digits and make sure we don't let them type more
            if fractionalDigits > maximumFractionalDigits {
                return false
            }
        }

        // Forward to the delegate
        if let forwardDelegateResult = self.forwardDelegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) {
            return forwardDelegateResult
        }

        return true
    }
    
    /// Counts the decimal characters in the string.
    /// The counting will stop at the end of the string, or at any non-decimal character.
    /// - parameter string: The string to count.
    /// - returns: The decimal character count.
    internal func countDecimalsIn(string: String.SubSequence) -> Int {
        var count: Int = 0
        var currentIndex = string.startIndex
        let endIndex = string.endIndex
        
        while currentIndex != endIndex {
            // Check for 0-9
            if "0123456789".contains(string[currentIndex]) {
                count += 1
                currentIndex = string.index(after: currentIndex)
            } else { // If we come accross anything else, stop counting
                break
            }
        }

        return count
    }
}
