//
//  EquationNumber.swift
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

import SwiftUI
@available(iOS 16.0, *)
/// A view that draws a number next to an equation.
struct EquationNumber: View {
  
  // MARK: Types
  
  /// The side of the equation that the number appears on.
  enum EquationSide {
    case left
    case right
  }
  
  // MARK: Public properties
  
  /// The index of the block attached to this number.
  let blockIndex: Int
  
  /// The side of the equation that this number appears on.
  let side: EquationSide
  
  // MARK: Private properties
  
  /// The view's equation number mode.
  @Environment(\.equationNumberMode) private var equationNumberMode
  
  /// The view's equation starting number.
  @Environment(\.equationNumberStart) private var equationNumberStart
  
  /// The view's equation number's offset.
  @Environment(\.equationNumberOffset) private var equationNumberOffset
  
  /// The view's equation number formatter.
  @Environment(\.formatEquationNumber) private var formatEquationNumber
  
  /// The number to draw in the view
  private var number: Text {
    Text(formatEquationNumber(equationNumberStart + blockIndex))
  }
  
  // MARK: View body
  
  var body: some View {
    switch equationNumberMode {
    case .left:
      if side == .left {
        number
          .padding([.leading], equationNumberOffset)
      }
      else {
        number
          .padding([.leading], equationNumberOffset)
          .foregroundColor(.clear)
      }
      Spacer(minLength: 0)
    case .right:
      Spacer(minLength: 0)
      if side == .right {
        number
          .padding([.trailing], equationNumberOffset)
      }
      else {
        number
          .padding([.trailing], equationNumberOffset)
          .foregroundColor(.clear)
      }
    default:
      EmptyView()
    }
  }
  
}
@available(iOS 16.0, *)
struct EquationNumber_Previews: PreviewProvider {
  static var previews: some View {
    EquationNumber(blockIndex: 0, side: .left)
      .environment(\.equationNumberMode, .left)
  }
}
