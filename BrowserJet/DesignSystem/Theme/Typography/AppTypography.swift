//
//  AppTypography.swift
//  browserjet-wkwebview
//
//  Created by Moiz Ul Hasan on 10/02/2026.
//

protocol AppTypography {
    // Title
    var title1: Typography { get } // Welcome Gabriel

    // Body
    var textBody1: Typography { get } // No Of Tabs
    var textBody2: Typography { get }

    var heading1: Typography { get }
    var heading4: Typography { get }

    // UI / Buttons
    var button: Typography { get }

    // textfield (launcher)
    var launcherField: Typography { get }
    var activationField: Typography { get }
    var textCaption: Typography { get }
}
