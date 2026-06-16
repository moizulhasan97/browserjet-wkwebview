//
//  AboutPanelOptionsBuilder.swift
//  BrowserJet
//
//  Created by Moiz Ul Hasan on 16/05/2026.
//

import AppKit

//  Builds the options dictionary for the standard macOS About panel,
//  used as a fallback when the rich AboutBrowserJetWindowController
//  can't render (e.g. pre-activation, before a license is stored).
//
enum AboutPanelOptionsBuilder {
    
    static func build(bundle: Bundle = .main) -> [NSApplication.AboutPanelOptionKey: Any] {
        var options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationName: "BrowserJet",
            .applicationVersion: bundle.appVersion,
            .version: bundle.buildNumber,
            .credits: makeCredits()
        ]
        
        if let icon = NSImage(named: "ic_logo") {
            options[.applicationIcon] = icon
        }
        
        return options
    }
    
    private static func makeCredits() -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(taglineParagraph())
        result.append(linksParagraph())
        result.append(buildInfoParagraph())
        result.append(copyrightParagraph())
        return result
    }
    
    private static func taglineParagraph() -> NSAttributedString {
        paragraph(
            "The high-performance browser for arbitrage and beyond.\n",
            font: .systemFont(ofSize: 11),
            color: .secondaryLabelColor,
            spacing: 8
        )
    }
    
    private static func linksParagraph() -> NSAttributedString {
        let style = centeredStyle(spacing: 6)
        let result = NSMutableAttributedString()
        
        result.append(link("Website", url: "https://browserjet.com", style: style))
        result.append(separator(style: style))
        result.append(link("Support", url: "https://browserjet.com/contact", style: style))
        result.append(separator(style: style))
        result.append(link("Twitter", url: "https://twitter.com/browserjet", style: style))
        result.append(NSAttributedString(string: "\n", attributes: [.paragraphStyle: style]))
        
        return result
    }
    
    private static func buildInfoParagraph() -> NSAttributedString {
        paragraph(
            "Build channel: \(AppEnvironment.current.displayName)\n",
            font: .systemFont(ofSize: 10),
            color: .tertiaryLabelColor
        )
    }
    
    private static func copyrightParagraph() -> NSAttributedString {
        let year = Calendar(identifier: .gregorian).component(.year, from: Date())
        return paragraph(
            "© \(year) BrowserJet. All rights reserved.",
            font: .systemFont(ofSize: 10),
            color: .tertiaryLabelColor
        )
    }
    
    private static func paragraph(
        _ text: String,
        font: NSFont,
        color: NSColor,
        spacing: CGFloat = 0
    ) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: centeredStyle(spacing: spacing)
            ]
        )
    }
    
    private static func centeredStyle(spacing: CGFloat = 0) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.paragraphSpacing = spacing
        return style
    }
    
    private static func separator(style: NSParagraphStyle) -> NSAttributedString {
        NSAttributedString(
            string: "  •  ",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.tertiaryLabelColor,
                .paragraphStyle: style
            ]
        )
    }
    
    private static func link(
        _ title: String,
        url: String,
        style: NSParagraphStyle
    ) -> NSAttributedString {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .paragraphStyle: style
        ]
        
        if let url = URL(string: url) {
            attrs[.link] = url
        }
        
        return NSAttributedString(string: title, attributes: attrs)
    }
}
