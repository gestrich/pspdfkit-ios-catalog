//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import SwiftUI
import PSPDFKitUI
import Combine

class SwiftUISettingsExample: Example {

    override init() {
        super.init()

        title = "SwiftUI Settings Example"
        contentDescription = "Shows how to show a PDFViewController in SwiftUI with Settings."
        category = .swiftUI
        priority = 11

        // Do not show the example in the list if running on iOS 12.
        if #available(iOS 13, *) {} else {
            targetDevice = []
        }
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        if #available(iOS 13, *) {
            let document = AssetLoader.writableDocument(withName: .quickStart, overrideIfExists: false)
            let swiftUIView = SwiftUISettingsExampleView(document: document)
            return UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
        }
        return nil
    }
}

@available(iOS 13.0, *)
private struct SwiftUISettingsExampleView: View {
    @ObservedObject var document: Document
    @State private var scrollDirection = ScrollDirection.horizontal
    @State private var pageTransition = PageTransition.scrollPerSpread
    @State private var pageIndex = PageIndex(0)

    var body: some View {
        return VStack(alignment: .center) {

            Text("SwiftUI Settings Example")
                .font(.largeTitle)
                .padding(.top, 100)

            // UIStepper is not allowed for Catalyst Mac Idiom.
            if !UIDevice.current.isCatalystMacIdiom {
                Stepper("Current Page: \(pageIndex + 1)", value: $pageIndex, in: 0...document.pageCount - 1)
                .padding()
            }

            SettingsView(scrollDirection: $scrollDirection, pageTransition: $pageTransition)
                .padding()

            PDFView(document: _document, pageIndex: $pageIndex)
                .useParentNavigationBar(true)
                .scrollDirection(scrollDirection)
                .pageTransition(pageTransition)
                .pageMode(.single)
                .userInterfaceViewMode(.always)
                .spreadFitting(.fill)
        }

        // Prevent jumping of the content as we show/hide the navigation bar
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: Settings Logic

extension ScrollDirection: CaseIterable {
    public static var allCases: [Self] {
        [.horizontal, .vertical]
    }
}

@available(iOS 13.0, *)
extension ScrollDirection: Localizable {
    var localizedName: LocalizedStringKey {
        switch self {
        case .horizontal: return "Horizontal"
        case .vertical: return "Vertical"
        }
    }
}

extension PageTransition: CaseIterable {
    public static var allCases: [Self] {
        [.scrollPerSpread, .scrollContinuous, .curl]
    }
}

@available(iOS 13.0, *)
extension PageTransition: Localizable {
    var localizedName: LocalizedStringKey {
        switch self {
        case .scrollPerSpread: return "Scroll per Spread"
        case .scrollContinuous: return "Scroll Continuous"
        case .curl: return "Page Curl"
        }
    }
}

@available(iOS 13.0, *)
struct NamedPicker<EnumType>: View where EnumType: Hashable & Equatable & Localizable,
                                         EnumType.AllCases: RandomAccessCollection {
    let title: String
    @Binding var value: EnumType
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        VStack {
            Text(title)
            Picker(selection: $value, label: Text(title)) {
                ForEach(EnumType.allCases, id: \EnumType.self) { value in
                    Text(value.localizedName).tag(value)
                }
            }.pickerStyle(SegmentedPickerStyle())
        }
    }
}

@available(iOS 13.0, *)
struct SettingsView: View {
    @Binding var scrollDirection: ScrollDirection
    @Binding var pageTransition: PageTransition

    var body: some View {
        AdaptiveStack {
            NamedPicker(title: "Scroll Direction", value: $scrollDirection)
            NamedPicker(title: "Page Transition", value: $pageTransition)
        }
    }
}

// MARK: Previews

@available(iOS 13.0, *)
struct SwiftUISettinsExamplePreviews: PreviewProvider {
    static var previews: some View {
        let document = AssetLoader.document(withName: .quickStart)
        SwiftUISettingsExampleView(document: document)
    }
}
