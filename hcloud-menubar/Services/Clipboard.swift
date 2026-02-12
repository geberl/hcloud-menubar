import AppKit
import Foundation

func copyToClipboard(content: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.writeObjects([content as NSString])
}
