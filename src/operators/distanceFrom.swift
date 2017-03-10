/*
 Copyright 2016-present The Material Motion Authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

extension MotionObservableConvertible where T == CGFloat {

  /** Emits the distance between the incoming value and the location. */
  public func distance(from location: CGFloat) -> MotionObservable<CGFloat> {
    return _map(#function, args: [location]) {
      fabs($0 - location)
    }
  }
}

extension MotionObservableConvertible where T == CGPoint {

  /** Emits the distance between the incoming value and the location. */
  public func distance(from location: CGPoint) -> MotionObservable<CGFloat> {
    return _map(#function, args: [location]) {
      let xDelta = $0.x - location.x
      let yDelta = $0.y - location.y
      return sqrt(xDelta * xDelta + yDelta * yDelta)
    }
  }

  /** Emits the distance between the incoming value and the current value of location. */
  public func distance<O: MotionObservableConvertible>(from location: O) -> MotionObservable<CGFloat> where O.T == CGPoint {
    return _map(#function, args: [location]) {
      let locationValue = location._read()!
      let xDelta = $0.x - locationValue.x
      let yDelta = $0.y - locationValue.y
      return sqrt(xDelta * xDelta + yDelta * yDelta)
    }
  }
}
