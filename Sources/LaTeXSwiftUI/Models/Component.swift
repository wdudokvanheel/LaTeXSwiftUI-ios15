//
//  Component.swift
//  LaTeXSwiftUI
//
//  Copyright (c) 2023 Colin Campbell
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import Foundation
import MathJaxSwift
import SwiftUI

/// A block of components.
@available(iOS 16.0, *)
internal struct ComponentBlock: Hashable, Identifiable {
  
  /// The component's identifier.
  ///
  /// Unique to every instance.
  let id = UUID()
  
  /// The block's components.
  let components: [Component]
  
  /// True iff this block has only one component and that component is
  /// not inline.
  var isEquationBlock: Bool {
    components.count == 1 && !components[0].type.inline
  }
  
  /// Creates the image view and its size for the given block.
  ///
  /// If the block isn't an equation block, then this method returns `nil`.
  ///
  /// - Parameter block: The block.
  /// - Returns: The image, its size, and any associated error text.
  @MainActor func image(
    font: Font,
    displayScale: CGFloat,
    renderingMode: Image.TemplateRenderingMode
  ) -> (Image, CGSize, String?)? {
    guard isEquationBlock, let component = components.first else {
      return nil
    }
    return component.convertToImage(
      font: font,
      displayScale: displayScale,
      renderingMode: renderingMode)
  }
  
}

@available(iOS 16.0, *)
/// A LaTeX component.
internal struct Component: CustomStringConvertible, Equatable, Hashable {
  
  /// A LaTeX component type.
  enum ComponentType: String, Equatable, CustomStringConvertible {
    
    /// A text component.
    case text
    
    /// An inline equation component.
    ///
    /// - Example: `$x^2$`
    case inlineEquation
    
    /// A TeX-style block equation.
    ///
    /// - Example: `$$x^2$$`.
    case texEquation
    
    /// A block equation.
    ///
    /// - Example: `\[x^2\]`
    case blockEquation
    
    /// A named equation component.
    ///
    /// - Example: `\begin{equation}x^2\end{equation}`
    case namedEquation
    
    /// A named equation component.
    ///
    /// - Example: `\begin{equation*}x^2\end{equation*}`
    case namedNoNumberEquation
    
    /// The component's description.
    var description: String {
      rawValue
    }
    
    /// The component's left terminator.
    var leftTerminator: String {
      switch self {
      case .text: return ""
      case .inlineEquation: return "$"
      case .texEquation: return "$$"
      case .blockEquation: return "\\["
      case .namedEquation: return "\\begin{equation}"
      case .namedNoNumberEquation: return "\\begin{equation*}"
      }
    }
    
    /// The component's right terminator.
    var rightTerminator: String {
      switch self {
      case .text: return ""
      case .inlineEquation: return "$"
      case .texEquation: return "$$"
      case .blockEquation: return "\\]"
      case .namedEquation: return "\\end{equation}"
      case .namedNoNumberEquation: return "\\end{equation*}"
      }
    }
    
    /// Whether or not this component is inline.
    var inline: Bool {
      switch self {
      case .text, .inlineEquation: return true
      default: return false
      }
    }
    
    /// True iff the component is not `text`.
    var isEquation: Bool {
      return self != .text
    }
  }
  
  /// The component's inner text.
  let text: String
  
  /// The component's type.
  let type: ComponentType
  
  /// The component's SVG image.
  let svg: SVG?
  
  /// The original input text that created this component.
  var originalText: String {
    "\(type.leftTerminator)\(text)\(type.rightTerminator)"
  }
  
  /// The component's original text with newlines trimmed.
  var originalTextTrimmingNewlines: String {
    originalText.trimmingCharacters(in: .newlines)
  }
  
  /// The component's conversion options.
  var conversionOptions: ConversionOptions {
    ConversionOptions(display: !type.inline)
  }
  
  /// The component's description.
  var description: String {
    return "(\(type), \"\(text)\")"
  }
  
  // MARK: Initializers
  
  /// Initializes a component.
  ///
  /// The text passed to the component is stripped of the left and right
  /// terminators defined in the component's type.
  ///
  /// - Parameters:
  ///   - text: The component's text.
  ///   - type: The component's type.
  ///   - svg: The rendered SVG (only applies to equations).
  init(text: String, type: ComponentType, svg: SVG? = nil) {
    if type.isEquation {
      var text = text
      if text.hasPrefix(type.leftTerminator) {
        text = String(text[text.index(text.startIndex, offsetBy: type.leftTerminator.count)...])
      }
      if text.hasSuffix(type.rightTerminator) {
        text = String(text[..<text.index(text.endIndex, offsetBy: -type.rightTerminator.count)])
      }
      self.text = text
    }
    else {
      self.text = text
    }
    
    self.type = type
    self.svg = svg
  }
  
}

// MARK: Methods
@available(iOS 16.0, *)
extension Component {
  
  /// Converts the component to a `Text` view.
  ///
  /// - Parameters:
  ///   - font: The font to use.
  ///   - displayScale: The view's display scale.
  ///   - renderingMode: The image rendering mode.
  ///   - errorMode: The error handling mode.
  ///   - isLastComponentInBlock: Whether or not this is the last component in
  ///     the block that contains it.
  /// - Returns: A text view.
  @MainActor func convertToText(
    font: Font,
    displayScale: CGFloat,
    renderingMode: Image.TemplateRenderingMode,
    errorMode: LaTeX.ErrorMode,
    blockRenderingMode: LaTeX.BlockMode,
    isInEquationBlock: Bool
  ) -> Text {
    // Get the component's text
    let text: Text
    if let svg = svg {
      // Do we have an error?
      if let errorText = svg.errorText, errorMode != .rendered {
        switch errorMode {
        case .original:
          // Use the original tex input
          text = Text(blockRenderingMode == .alwaysInline ? originalTextTrimmingNewlines : originalText)
        case .error:
          // Use the error text
          text = Text(errorText)
        default:
          text = Text("")
        }
      }
      else if let (image, _, _) = convertToImage(
        font: font,
        displayScale: displayScale,
        renderingMode: renderingMode
      ) {
        let xHeight = _Font.preferredFont(from: font).xHeight
        let offset = svg.geometry.verticalAlignment.toPoints(xHeight)
        text = Text(image).baselineOffset(blockRenderingMode == .alwaysInline || !isInEquationBlock ? offset : 0)
      }
      else {
        text = Text("")
      }
    }
    else if blockRenderingMode == .alwaysInline {
      text = Text(originalTextTrimmingNewlines)
    }
    else {
      text = Text(originalText)
    }
    
    return text
  }
  
  /// Converts the component to an image.
  ///
  /// - Parameters:
  ///   - font: The font to use.
  ///   - displayScale: The current display scale.
  ///   - renderingMode: The current rendering mode.
  /// - Returns: Image details.
  @MainActor func convertToImage(
    font: Font,
    displayScale: CGFloat,
    renderingMode: Image.TemplateRenderingMode
  ) -> (Image, CGSize, String?)? {
    guard let svg = svg else {
      return nil
    }
    guard let imageData = Renderer.shared.convertToImage(
      svg: svg,
      font: font,
      displayScale: displayScale,
      renderingMode: renderingMode) else {
      return nil
    }
    return (imageData.0, imageData.1, svg.errorText)
  }
  
}
