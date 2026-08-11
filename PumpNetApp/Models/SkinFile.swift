import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct SkinFile: Transferable {
    let data: Data
    let filename: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .png) { skin in
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("PumpNetApp", isDirectory: true)
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            let fileURL = directory.appendingPathComponent(skin.filename)
            try skin.data.write(to: fileURL, options: .atomic)
            return SentTransferredFile(fileURL)
        }
    }
}
