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
import IndefiniteObservable

/**
 A MotionRuntime writes the output of streams to properties and observes their overall state.
 */
public class MotionRuntime {

  /** All motion in this runtime is relative to this view. */
  public let containerView: UIView

  /** Creates a motion runtime instance. */
  public init(containerView: UIView) {
    self.parent = nil
    self.containerView = containerView
  }

  public func add(_ interaction: ViewInteraction, to reactiveView: ReactiveUIView) {
    interaction.add(to: reactiveView, withRuntime: self)
    viewInteractions.append(interaction)
  }

  public func add(_ interaction: ViewInteraction, to view: UIView) {
    add(interaction, to: get(view))
  }

  public func add<T, P: ReactivePropertyConvertible>(_ stream: MotionObservable<T>, to property: P) where P.T == T {
    write(stream, to: property.asProperty())
  }

  public func add<I: PropertyInteraction, P: ReactivePropertyConvertible>(_ interaction: I, to property: P) where I.T == P.T {
    interaction.add(to: property.asProperty(), withRuntime: self)
  }

  public func add<I: TransitionInteraction, P: ReactivePropertyConvertible>(_ interaction: I, to property: P) where I.ValueType == P.T, I: PropertyInteraction {
    let property = property.asProperty()
    property.value = interaction.initialValue()
    interaction.add(to: property as! ReactiveProperty<I.T>, withRuntime: self)
  }

  public func get(_ view: UIView) -> ReactiveUIView {
    if let reactiveObject = reactiveViews[view] {
      return reactiveObject
    }
    let reactiveObject = ReactiveUIView(view, runtime: self)
    reactiveViews[view] = reactiveObject
    return reactiveObject
  }
  private var reactiveViews: [UIView: ReactiveUIView] = [:]

  public func get(_ layer: CALayer) -> ReactiveCALayer {
    if let reactiveObject = reactiveLayers[layer] {
      return reactiveObject
    }
    let reactiveObject = ReactiveCALayer(layer)
    reactiveLayers[layer] = reactiveObject
    return reactiveObject
  }
  private var reactiveLayers: [CALayer: ReactiveCALayer] = [:]

  public func get<O: UIGestureRecognizer>(_ gestureRecognizer: O) -> ReactiveUIGestureRecognizer<O> {
    if let reactiveObject = reactiveGestureRecognizers[gestureRecognizer] {
      return unsafeBitCast(reactiveObject, to: ReactiveUIGestureRecognizer<O>.self)
    }

    let reactiveObject = ReactiveUIGestureRecognizer<O>(gestureRecognizer, containerView: containerView)

    if reactiveObject.gestureRecognizer.view == nil {
      containerView.addGestureRecognizer(reactiveObject.gestureRecognizer)
    }

    reactiveGestureRecognizers[gestureRecognizer] = reactiveObject as! ReactiveUIGestureRecognizer<O>
    return reactiveObject
  }
  private var reactiveGestureRecognizers: [UIGestureRecognizer: AnyObject] = [:]

  /** Subscribes to the stream, writes its output to the given property, and observes its state. */
  private func write<O: MotionObservableConvertible, T>(_ stream: O, to property: ReactiveProperty<T>) where O.T == T {
    let token = NSUUID().uuidString
    subscriptions.append(stream.asStream().subscribe(next: { property.value = $0 }, coreAnimation: property.coreAnimation))
  }

  /**
   Creates a child runtime instance.

   Streams registered to a child runtime will affect the state on that runtime and all of its
   ancestors.
   */
  public func createChild() -> MotionRuntime {
    return MotionRuntime(parent: self)
  }

  /** Creates a child motion runtime instance. */
  private init(parent: MotionRuntime) {
    self.parent = parent
    self.containerView = parent.containerView
    parent.children.append(self)
  }

  public func whenAllAtRest(_ streams: [MotionObservable<MotionState>], body: @escaping () -> Void) {
    var subscriptions: [Subscription] = []
    var activeIndices = Set<Int>()
    for (index, stream) in streams.enumerated() {
      subscriptions.append(stream.dedupe().subscribe { state in
        if state == .active {
          activeIndices.insert(index)

        } else if activeIndices.contains(index) {
          activeIndices.remove(index)

          if activeIndices.count == 0 {
            body()
          }
        }
      })
    }
    self.subscriptions.append(contentsOf: subscriptions)
  }

  private weak var parent: MotionRuntime?
  private var children: [MotionRuntime] = []
  private var subscriptions: [Subscription] = []
  private var viewInteractions: [ViewInteraction] = []
}
