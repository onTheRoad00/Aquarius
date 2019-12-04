//
//  GSTRootView.swift
//  Aquarius
//
//  Created by Crazy凡 on 2019/11/30.
//  Copyright © 2019 Crazy凡. All rights reserved.
//

import SwiftUI

private let supportType: String = kUTTypeFileURL as String

struct GSTRootView: View {
    @State private var isTargeted: Bool = false
    @State private var isProcessing: Bool = false

    var body: some View {
        ZStack {
            Text(isProcessing ? "Processing" : "Drag the Packge here")
                .frame(width: 300, height: 300, alignment: .center)
                .onDrop(of: [supportType], isTargeted: $isTargeted) { (items: [NSItemProvider]) -> Bool in
                    guard let item = items.first(where: { $0.canLoadObject(ofClass: URL.self) }) else { return false }
                    DispatchQueue.global().async {
                        item.loadItem(forTypeIdentifier: supportType, options: nil) { (data, error) in
                            if let _ = error {
                                // TODO error
                                return
                            }

                            guard let urlData = data as? Data,
                                let urlString = String(data: urlData, encoding: .utf8),
                                let url = URL(string: urlString) else {
                                // TODO error
                                return
                            }

                            guard ["zip", "ipa"].contains(url.pathExtension.lowercased()) else {
                                // TODO error
                                return
                            }

                            GetStringsTool.getStrings(from: url.path) { result in
                                switch result {
                                case .success(let path):
                                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                                case .failure(let error):
                                    _ = Alert(
                                        title: Text("Error!"),
                                        message: Text("\(error.rawValue)"),
                                        dismissButton: .default(Text("Got it!")))
                                }
                                self.isProcessing = false
                            }
                            self.isProcessing = true
                        }
                    }
                    return true
                }

            if isProcessing {
                ActivityIndicator()
                    .frame(width: 200, height: 200, alignment: .center)
            }
        }
    }
}

struct GSTRootView_Previews: PreviewProvider {
    static var previews: some View {
        GSTRootView()
    }
}
