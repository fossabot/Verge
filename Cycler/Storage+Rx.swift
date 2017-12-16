//
//  Storage+Rx.swift
//  Cycler
//
//  Created by muukii on 12/15/17.
//  Copyright © 2017 muukii. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

private var storage_subject: Void?
private var storage_diposeBag: Void?

extension Storage {

  private var subject: BehaviorRelay<T> {

    if let associated = objc_getAssociatedObject(self, &storage_subject) as? BehaviorRelay<T> {

      return associated

    } else {

      let associated = BehaviorRelay<T>.init(value: value)
      objc_setAssociatedObject(self, &storage_subject, associated, .OBJC_ASSOCIATION_RETAIN)

      add(subscriber: { (value) in
        associated.accept(value)
      })

      return associated
    }
  }

  private var disposeBag: DisposeBag {

    if let associated = objc_getAssociatedObject(self, &storage_diposeBag) as? DisposeBag {

      return associated

    } else {

      let associated = DisposeBag()
      objc_setAssociatedObject(self, &storage_diposeBag, associated, .OBJC_ASSOCIATION_RETAIN)

      return associated
    }
  }

  public func asObservable() -> Observable<T> {
    return subject.asObservable()
  }

  public func asObservable<S>(keyPath: KeyPath<T, S>) -> Observable<S> {
    return asObservable()
      .map { $0[keyPath: keyPath] }
  }

  public func asDriver() -> Driver<T> {
    return subject.asDriver()
  }

  public func asDriver<S>(keyPath: KeyPath<T, S>) -> Driver<S> {
    return asDriver()
      .map { $0[keyPath: keyPath] }
  }

  public func map<U>(_ closure: @escaping (T) -> U) -> Storage<U> {

    let m_state = MutableStorage.init(closure(value))

    let state = m_state.asStorage()

    let subscription = asObservable()
      .map(closure)
      .subscribe(onNext: { [weak m_state] o in
        m_state?.replace(o)
      })

    state.disposeBag.insert(subscription)
    disposeBag.insert(subscription)

    return state
  }
}