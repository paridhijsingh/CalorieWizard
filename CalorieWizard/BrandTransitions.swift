//
//  BrandTransitions.swift
//  CalorieWizard
//

import SwiftUI

enum BrandTransitions {
    static let page = Animation.spring(response: 0.62, dampingFraction: 0.86)
    static let cover = Animation.spring(response: 0.52, dampingFraction: 0.88)
    static let quick = Animation.spring(response: 0.38, dampingFraction: 0.84)

    static var landingExit: AnyTransition {
        .asymmetric(
            insertion: .opacity,
            removal: .opacity
                .combined(with: .scale(scale: 1.04, anchor: .center))
                .combined(with: .offset(y: -18))
        )
    }

    static var hubEnter: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .scale(scale: 0.96, anchor: .center))
                .combined(with: .offset(y: 28)),
            removal: .opacity.combined(with: .scale(scale: 0.98))
        )
    }

    static var destinationCover: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.98, anchor: .trailing)),
            removal: .move(edge: .trailing)
                .combined(with: .opacity)
        )
    }
}
